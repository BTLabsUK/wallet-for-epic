//! Offline tests on mainnet parameters: mnemonics, create/open/password, restore, error kinds.
//! No node is needed; the node URL points at a closed port.

mod common;

use common::*;
use epic_wallet_core::api::types::{Chain, WalletErrorKind};
use epic_wallet_core::api::wallet::{
    generate_mnemonic, node_tip, validate_mnemonic, wallet_exists, EpicWallet,
};

fn cfg(dir: &std::path::Path) -> epic_wallet_core::api::types::WalletConfig {
    config(dir, Chain::Mainnet, DEAD_NODE)
}

#[test]
fn generates_valid_phrases_of_both_lengths() {
    for words in [12u32, 24] {
        let phrase = generate_mnemonic(words).expect("generate");
        assert_eq!(phrase.split_whitespace().count(), words as usize);
        assert!(
            validate_mnemonic(phrase.clone()),
            "{words}-word phrase must validate"
        );
        assert!(
            validate_mnemonic(phrase.to_uppercase()),
            "validation is case-insensitive"
        );
    }
    assert!(
        generate_mnemonic(24).expect("generate") != generate_mnemonic(24).expect("generate"),
        "two phrases must differ"
    );
}

#[test]
fn rejects_bad_word_counts_and_bad_phrases() {
    assert_eq!(
        kind_of(generate_mnemonic(13)),
        WalletErrorKind::InvalidArgument
    );
    assert!(!validate_mnemonic(String::new()));
    assert!(!validate_mnemonic("not a real phrase at all".into()));
    // Valid words with a broken checksum: a 12-word phrase has a 4-bit checksum, so at least one
    // of five different last words must fail it.
    let phrase = generate_mnemonic(12).expect("generate");
    let base: Vec<String> = phrase.split_whitespace().map(String::from).collect();
    let broken = ["abandon", "ability", "able", "about", "above"]
        .iter()
        .filter(|w| **w != base[11])
        .any(|w| {
            let mut words = base.clone();
            words[11] = (*w).to_owned();
            !validate_mnemonic(words.join(" "))
        });
    assert!(broken, "a changed last word must break the checksum");
}

#[test]
fn create_open_and_password_checks() {
    let dir = tempfile::tempdir().expect("tempdir");
    let config = cfg(dir.path());
    assert!(!wallet_exists(config.clone()));
    assert_eq!(
        kind_of(EpicWallet::open(config.clone(), PASSWORD.into())),
        WalletErrorKind::WalletNotFound
    );

    let wallet = EpicWallet::create(config.clone(), None, PASSWORD.into()).expect("create");
    assert!(wallet_exists(config.clone()));
    let phrase = wallet.mnemonic(PASSWORD.into()).expect("mnemonic");
    assert_eq!(phrase.split_whitespace().count(), 24);
    assert!(validate_mnemonic(phrase.clone()));
    assert_eq!(
        kind_of(wallet.mnemonic("wrong".into())),
        WalletErrorKind::WrongPassword
    );
    let address = wallet.epicbox_address().expect("address");
    assert!(
        address.ends_with("@epicbox.epiccash.com"),
        "port 443 is omitted"
    );

    // Offline: the local summary works, and a fresh wallet holds nothing.
    let summary = wallet.summary(false, 10).expect("summary");
    assert_eq!(summary.total, 0);
    assert!(!summary.validated_with_node);
    assert!(wallet.transactions(false).expect("txs").is_empty());
    drop(wallet);

    assert_eq!(
        kind_of(EpicWallet::create(config.clone(), None, PASSWORD.into())),
        WalletErrorKind::WalletAlreadyExists
    );
    assert_eq!(
        kind_of(EpicWallet::open(config.clone(), "wrong".into())),
        WalletErrorKind::WrongPassword
    );
    let reopened = EpicWallet::open(config, PASSWORD.into()).expect("open");
    assert!(
        reopened.mnemonic(PASSWORD.into()).expect("mnemonic") == phrase,
        "reopened wallet must hold the same seed"
    );
    assert_eq!(reopened.epicbox_address().expect("address"), address);
}

#[test]
fn restore_roundtrip_gives_same_seed_and_address() {
    let phrase = generate_mnemonic(24).expect("generate");
    let a = tempfile::tempdir().expect("tempdir");
    let b = tempfile::tempdir().expect("tempdir");
    let mut config_b = cfg(b.path());
    config_b.epicbox_domain = "relay.example".into();
    config_b.epicbox_port = 8443;

    let wa = EpicWallet::create(cfg(a.path()), Some(phrase.clone()), PASSWORD.into())
        .expect("restore a");
    // Extra whitespace and capitals are normalised away.
    let messy = format!("  {}  ", phrase.to_uppercase().replace(' ', "   "));
    let wb = EpicWallet::create(config_b, Some(messy), "other password".into()).expect("restore b");

    assert!(wa.mnemonic(PASSWORD.into()).expect("mnemonic") == phrase);
    assert!(wb.mnemonic("other password".into()).expect("mnemonic") == phrase);
    let addr_a = wa.epicbox_address().expect("address");
    let addr_b = wb.epicbox_address().expect("address");
    let (key_a, _) = addr_a.split_once('@').expect("key@domain");
    let (key_b, host_b) = addr_b.split_once('@').expect("key@domain");
    assert_eq!(key_a, key_b, "same seed, same address key");
    assert_eq!(host_b, "relay.example:8443");
}

#[test]
fn restore_with_invalid_phrase_writes_nothing() {
    let dir = tempfile::tempdir().expect("tempdir");
    let config = cfg(dir.path());
    assert_eq!(
        kind_of(EpicWallet::create(
            config.clone(),
            Some("abandon abandon abandon".into()),
            PASSWORD.into()
        )),
        WalletErrorKind::InvalidMnemonic
    );
    assert!(!wallet_exists(config));
}

#[test]
fn error_kinds_for_bad_input() {
    let dir = tempfile::tempdir().expect("tempdir");
    let wallet = EpicWallet::create(cfg(dir.path()), None, PASSWORD.into()).expect("create");
    assert_eq!(
        kind_of(epic_wallet_core::api::wallet::inspect_slate(
            "{not json".into()
        )),
        WalletErrorKind::InvalidSlate
    );
    assert_eq!(
        kind_of(wallet.receive_slate("{not json".into())),
        WalletErrorKind::InvalidSlate
    );
    assert_eq!(
        kind_of(wallet.finalize_and_post("{}".into())),
        WalletErrorKind::InvalidSlate
    );
    assert_eq!(
        kind_of(wallet.cancel_transaction(4242)),
        WalletErrorKind::NodeUnreachable,
        "cancel refreshes from the node first"
    );
    assert_eq!(
        kind_of(wallet.create_send_slate(0, 10)),
        WalletErrorKind::InvalidArgument
    );
    assert_eq!(
        kind_of(node_tip(cfg(dir.path()))),
        WalletErrorKind::NodeUnreachable
    );
    let mut empty = cfg(dir.path());
    empty.data_dir = String::new();
    assert_eq!(
        kind_of(EpicWallet::open(empty, PASSWORD.into())),
        WalletErrorKind::InvalidArgument
    );
}

#[test]
fn contacts_persist_and_history_files_open_only_in_the_same_seed() {
    use epic_wallet_core::api::types::Contact;

    let phrase = generate_mnemonic(24).expect("generate");
    let a = tempfile::tempdir().expect("tempdir");
    let wa =
        EpicWallet::create(cfg(a.path()), Some(phrase.clone()), PASSWORD.into()).expect("create a");
    let blank = Contact {
        id: String::new(),
        name: " ".into(),
        address: "x".into(),
        note: None,
    };
    assert_eq!(
        kind_of(wa.save_contact(blank)),
        WalletErrorKind::InvalidArgument
    );
    let bob = wa
        .save_contact(Contact {
            id: String::new(),
            name: "Bob".into(),
            address: " bob@epicbox.example ".into(),
            note: Some("  ".into()),
        })
        .expect("save");
    assert!(!bob.id.is_empty());
    assert_eq!(bob.address, "bob@epicbox.example");
    assert_eq!(bob.note, None);
    let renamed = wa
        .save_contact(Contact {
            name: "Robert".into(),
            ..bob.clone()
        })
        .expect("rename");
    assert_eq!(renamed.id, bob.id);
    wa.set_tx_note("s:unknown".into(), Some("kept".into()))
        .expect("note");
    let file = wa.export_history().expect("export");
    assert_eq!(&file[..4], b"WFEH");
    let csv = wa.export_history_csv().expect("csv");
    assert_eq!(csv.lines().count(), 1, "header only: no transactions");
    drop(wa);

    // Reopening reads the archive back.
    let wa = EpicWallet::open(cfg(a.path()), PASSWORD.into()).expect("reopen");
    let names: Vec<_> = wa
        .contacts()
        .expect("contacts")
        .into_iter()
        .map(|c| c.name)
        .collect();
    assert_eq!(names, ["Robert"]);
    drop(wa);

    // A restore of the same phrase opens the file, once.
    let b = tempfile::tempdir().expect("tempdir");
    let wb = EpicWallet::create(cfg(b.path()), Some(phrase), "another password".into())
        .expect("restore");
    let first = wb.import_history(file.clone()).expect("import");
    assert_eq!(first.contacts_added, 1);
    let second = wb.import_history(file.clone()).expect("import again");
    assert_eq!(
        (second.merged, second.added, second.contacts_added),
        (0, 0, 0)
    );
    assert_eq!(wb.contacts().expect("contacts").len(), 1);
    let meta_before = std::fs::read(b.path().join("wfe_meta.json")).expect("meta");
    let _ = wb
        .import_history(file.clone())
        .expect("import a third time");
    assert_eq!(
        std::fs::read(b.path().join("wfe_meta.json")).expect("meta"),
        meta_before
    );

    let mut damaged = file.clone();
    let last = damaged.len() - 1;
    damaged[last] ^= 0x40;
    let e = wb.import_history(damaged).err().expect("damaged file");
    assert_eq!(e.kind, WalletErrorKind::InvalidArgument);
    assert!(e.message.contains("damaged"), "{}", e.message);
    drop(wb);

    // Another seed is told the file is not its own.
    let c = tempfile::tempdir().expect("tempdir");
    let wc = EpicWallet::create(cfg(c.path()), None, PASSWORD.into()).expect("create c");
    let e = wc.import_history(file).err().expect("wrong wallet");
    assert_eq!(e.kind, WalletErrorKind::InvalidArgument);
    assert!(
        e.message.contains("belongs to a different wallet"),
        "{}",
        e.message
    );
    assert!(wc.contacts().expect("contacts").is_empty());
    // Send-all needs the node.
    assert_eq!(
        kind_of(wc.estimate_max(10)),
        WalletErrorKind::NodeUnreachable
    );
}
