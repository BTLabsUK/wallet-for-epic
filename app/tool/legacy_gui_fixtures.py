#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Builds the IndexedDB fixtures of test/fixtures/legacy_gui with real Chromium.

The older Epic GUIs (Electron) keep contacts and per-wallet settings in IndexedDB 'Epicwallet'
(stores 'User' and 'Addressbook', made by JsStore, src/shared/idbService.js). The app reads those
LevelDB files without Chromium (lib/src/legacy/), so its tests need files Chromium itself wrote.
This script opens a throwaway Chromium profile per fixture, writes the rows the GUI would, closes
the browser and copies <profile>/Default/IndexedDB/<origin>.indexeddb.leveldb out under the name
the GUI's origin (app://.) gets: app_._0.indexeddb.leveldb.

Run with the Playwright venv's python (not the system one):

    python3 app/tool/legacy_gui_fixtures.py \
        --work "$TMPDIR/idb" --out app/test/fixtures/legacy_gui/idb

Fixtures made:
    gui616_log      6.1.6 rows (User account wN), still only in the .log write-ahead file
    gui531_table    5.3.1 rows, then enough writes and a reopen that they sit in .ldb tables
    gui600_log      6.0 rows overlapping gui531_table (the merge of both profiles)
"""
import argparse
import os
import shutil

from playwright.sync_api import sync_playwright

ORIGIN = 'http://epic.test'
PAGE = '<!doctype html><title>fixture</title>'

# JsStore's tables (idbService.js): primary key 'id' autoIncrement; the other columns indexed
SCHEMA_JS = r"""
const SCHEMA = {
  Addressbook: ['user_id', 'name', 'gender', 'country', 'city', 'onion', 'keybase', 'alwaysproof',
    'proofaddr', 'externalOne', 'externalTwo', 'notice'],
  AddressTransactions: ['user_id', 'slateid', 'type', 'address'],
  User: ['account', 'name', 'email', 'keybase', 'ngrok', 'language', 'nodeInternal',
    'ngrok_force_start', 'epicbox_domain'],
};
function openDb(version) {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open('Epicwallet', version);
    req.onupgradeneeded = () => {
      const db = req.result;
      for (const [name, cols] of Object.entries(SCHEMA)) {
        if (db.objectStoreNames.contains(name)) continue;
        const s = db.createObjectStore(name, { keyPath: 'id', autoIncrement: true });
        for (const c of cols) s.createIndex(c, c, { unique: name === 'User' && c === 'account' });
      }
    };
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
}
function tx(db, stores, fn) {
  return new Promise((resolve, reject) => {
    const t = db.transaction(stores, 'readwrite');
    const out = fn(t);
    t.oncomplete = () => resolve(out);
    t.onerror = () => reject(t.error);
    t.onabort = () => reject(t.error);
  });
}
function add(t, store, row) {
  const r = t.objectStore(store).add(row);
  const box = {};
  r.onsuccess = () => { box.id = r.result; };
  return box;
}
"""

EPICBOX_A = 'esWNvLomAJ2SHT6CU1F4ok2URGQnmUmCAp9XNwEP4N8JS4Ve8qcx'
EPICBOX_B = 'es7jHnbVkZzE2UGWUkzWrc4y4VoKZbg7FBaPUo2vXhJpe4jgXAA7'
ONION = '2gzyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid.onion'


def contact(user_id, name, **kw):
    row = dict(user_id=user_id, name=name, gender='male', country='', city='', onion='', keybase='',
               alwaysproof=False, proofaddr='', externalOne='', externalTwo='', notice='')
    row.update(kw)
    return row


def user(account, name, language, node_internal, epicbox):
    return dict(account=account, name=name, email='', keybase='', ngrok='', language=language,
                nodeInternal=node_internal, ngrok_force_start=False, epicbox_domain=epicbox)


# --- scenario scripts: each is an async JS body run on the fixture's origin ---

GUI616 = SCHEMA_JS + r"""
async (data) => {
  const db = await openDb(5);
  const ids = await tx(db, ['User'], (t) => data.users.map((u) => add(t, 'User', u)));
  const uid = ids.map((b) => b.id);
  const fix = (c) => ({ ...c, user_id: uid[c.user_id] });
  const keys = await tx(db, ['Addressbook'], (t) => data.contacts.map((c) => add(t, 'Addressbook', fix(c))));
  const id = (name) => keys[data.contacts.findIndex((c) => c.name === name)].id;
  const carol = data.contacts.find((c) => c.name === 'Carol');
  // Bob deleted; Carol's note and HTTP address changed
  if (carol) {
    await tx(db, ['Addressbook'], (t) => {
      const s = t.objectStore('Addressbook');
      s.delete(id('Bob'));
      s.put({ ...fix(carol), id: id('Carol'), notice: 'updated note', externalTwo: 'https://carol.example:3415' });
    });
  }
  // the wallet's own transaction links (not read by the importer)
  await tx(db, ['AddressTransactions'], (t) => {
    add(t, 'AddressTransactions', { user_id: uid[0], slateid: '0f1e2d3c-aaaa-bbbb-cccc-000000000001', type: 'send', address: keys[0].id, amount: 1.5, big: 2 ** 40, tags: ['a', 2, null, true], gone: undefined });
  });
  db.close();
  return 'ok';
}
"""

# a few MB written to a throwaway database: more than leveldb's write buffer, so the memtable (the
# Epicwallet rows with it) goes to an .ldb table. Deleting that database makes Chromium compact its
# key range, which drops the filler again; the Epicwallet rows stay, in a Snappy-compressed table.
FILL = r"""
async (rows) => {
  const db = await new Promise((resolve, reject) => {
    const req = indexedDB.open('Filler', 1);
    req.onupgradeneeded = () => req.result.createObjectStore('fill', { autoIncrement: true });
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
  const blob = 'x'.repeat(100000);
  await new Promise((resolve, reject) => {
    const t = db.transaction(['fill'], 'readwrite');
    for (let j = 0; j < rows; j++) t.objectStore('fill').add({ j, blob });
    t.oncomplete = resolve;
    t.onerror = () => reject(t.error);
  });
  db.close();
  await new Promise((resolve, reject) => {
    const req = indexedDB.deleteDatabase('Filler');
    req.onsuccess = resolve;
    req.onerror = () => reject(req.error);
  });
  return 'ok';
}
"""

# after the compaction: a change that lives in the .log on top of the table
LATER = SCHEMA_JS + r"""
async () => {
  const db = await openDb(5);
  await tx(db, ['Addressbook', 'User'], (t) => {
    const s = t.objectStore('Addressbook');
    const req = s.getAll();
    req.onsuccess = () => {
      const frank = req.result.find((c) => c.name === 'Frank');
      s.put({ ...frank, notice: 'changed after compaction' });
      const heidi = { ...frank, name: 'Heidi', externalTwo: 'https://heidi.example', notice: '' };
      delete heidi.id;
      add(t, 'Addressbook', heidi);
    };
  });
  db.close();
  return 'ok';
}
"""

TOUCH = SCHEMA_JS + r"""
async () => { const db = await openDb(5); db.close(); return 'ok'; }
"""


def users_616():
    return [user('w1', 'Główny portfel 💰', 'pl', False, 'epicbox.epiccash.com'),
            user('w2', 'Тестовый', 'en', True, 'epicbox.epic.tech')]


def contacts_616():
    return [
        contact(0, 'Alice', externalOne=EPICBOX_A + '@epicbox.epiccash.com', externalTwo='https://alice.example:3415',
                notice='paid for coffee'),
        contact(0, 'Zoë 李雷', onion=ONION, externalOne=EPICBOX_B, notice='日本語のメモ ✓'),
        contact(0, 'Alice', externalOne='duplicate row, same name and onion'),
        contact(0, 'Bob', externalOne=EPICBOX_B),
        contact(0, 'Carol', externalTwo='http://carol.example:3415', notice='first note'),
        contact(1, 'Dave', externalTwo='http://10.100.10.20:3415', alwaysproof=True, proofaddr='abc'),
    ]


def users_531():
    return [user('default', '', 'de', False, ''),
            user('alpha', 'Alpha', 'en', True, 'epicbox.epic.tech')]


def contacts_531():
    # 5.x rows: keybase, gender, country and city filled in as its form asked for them
    return [
        contact(0, 'Eve', gender='female', country='Deutschland', city='München', keybase='eve_kb',
                externalOne=EPICBOX_A),
        contact(1, 'Frank', country='Polska', city='Łódź', externalTwo='http://frank.example:3415'),
        contact(1, 'Shared', externalOne=EPICBOX_B, notice='in 5.3.1'),
        contact(1, 'Bob', externalOne=EPICBOX_B),
        contact(1, 'Carol', externalTwo='http://carol.old:3415', notice='first note'),
    ]


def users_600():
    return [user('alpha', 'Alpha (6.0)', 'cz', False, 'epicbox.fastepic.eu')]


def contacts_600():
    return [contact(0, 'Shared', externalOne=EPICBOX_B, notice='in 6.0'),
            contact(0, 'Grace', externalOne=EPICBOX_A, externalTwo='https://grace.example')]


def run(pw, chrome, profile, steps):
    """steps: [(script, arg)] per browser session; each session is a fresh launch on the profile"""
    for session in steps:
        ctx = pw.chromium.launch_persistent_context(profile, headless=True, executable_path=chrome)
        try:
            page = ctx.new_page()
            page.route(ORIGIN + '/**', lambda r: r.fulfill(status=200, content_type='text/html', body=PAGE))
            page.goto(ORIGIN + '/')
            for script, arg in session:
                res = page.evaluate(script, arg)
                assert res == 'ok', res
        finally:
            ctx.close()


def leveldb_dir(profile):
    base = os.path.join(profile, 'Default', 'IndexedDB')
    for name in os.listdir(base):
        if name.endswith('.indexeddb.leveldb'):
            return os.path.join(base, name)
    raise SystemExit('no leveldb under ' + base)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--work', required=True, help='a scratch dir for the Chromium profiles')
    ap.add_argument('--out', required=True, help='where the fixtures go')
    ap.add_argument('--chrome', default='', help='a chrome binary (default: Playwright\'s)')
    a = ap.parse_args()
    os.makedirs(a.work, exist_ok=True)

    data616 = {'users': users_616(), 'contacts': contacts_616()}
    data531 = {'users': users_531(), 'contacts': contacts_531()}
    data600 = {'users': users_600(), 'contacts': contacts_600()}
    fixtures = {
        'gui616_log': [[(GUI616, data616)]],
        # write, fill past the write buffer, then reopen twice: leveldb turns the log into tables
        'gui531_table': [[(GUI616, data531)], [(FILL, 60)], [(LATER, None)]],
        'gui600_log': [[(GUI616, data600)]],
    }
    with sync_playwright() as pw:
        chrome = a.chrome or pw.chromium.executable_path
        for name, steps in fixtures.items():
            profile = os.path.join(a.work, name)
            shutil.rmtree(profile, ignore_errors=True)
            run(pw, chrome, profile, steps)
            src = leveldb_dir(profile)
            dst = os.path.join(a.out, name, 'app_._0.indexeddb.leveldb')
            shutil.rmtree(dst, ignore_errors=True)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copytree(src, dst, ignore=shutil.ignore_patterns('LOCK', 'LOG', 'LOG.old'))
            print(name, sorted(os.listdir(dst)))


if __name__ == '__main__':
    main()
