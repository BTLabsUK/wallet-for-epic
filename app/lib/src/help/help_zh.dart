// SPDX-License-Identifier: Apache-2.0
/// Chinese help: the topics and sections of help_content.dart in Chinese, by the same ids. A topic or
/// section missing here shows in English.
library;

import 'help_content.dart';
import 'help_devices.dart';
import '../settings_file/host_settings.dart' show appConfig, hostSettings;

const List<HelpSection> helpSectionsZh = [
  (id: 'start', title: '入门', lede: '接收、发送，以及用文件付款。', art: 'help-start'),
  (id: 'how', title: 'Epic Cash 如何运作', lede: '双方钱包共同参与。确认、隐私、找零和手续费。', art: 'help-how'),
  (id: 'safety', title: '保护钱包安全', lede: '助记词既是备份，也是密钥。', art: 'help-safety'),
  (id: 'network', title: '节点与 Epicbox', lede: '钱包连接到什么，以及 Tor。', art: 'help-network'),
  (id: 'trouble', title: '出现问题时', lede: '常见原因及处理方法。', art: 'help-trouble'),
  (id: 'maintenance', title: '维护', lede: '磁盘上旧的钱包文件夹，以及设置文件。', art: 'help-maintenance'),
];

List<HelpTopic> helpTopicsZh(int confirmations, {required HelpPlatform platform, bool tor = true}) {
  final phone = platform == HelpPlatform.phone;
  // The words that differ between a computer and a phone.
  final device = phone ? '这部手机' : '这台电脑';
  final secret = phone ? '你的 PIN 码或密码短语' : '钱包密码';
  final nodePlace = phone ? '[[设置 › 网络与隐私 › 节点|Settings › Network & privacy › Node]]' : '[[设置 › 节点|Settings › Node]]';
  final epicboxPlace = phone ? '[[设置 › 网络与隐私 › Epicbox|Settings › Network & privacy › Epicbox]]' : '[[设置 › 交易 › Epicbox|Settings › Transactions › Epicbox]]';
  final torPlace = phone ? '[[设置 › 网络与隐私 › Tor 网络|Settings › Network & privacy › Tor network]]' : '[[设置 › 网络与隐私 › Tor|Settings › Network & privacy › Tor]]';
  final netPlace = '[[设置 › 网络与隐私|Settings › Network & privacy]]';
  final cancelPlace = phone ? '[[活动|Activity]]（打开该付款，然后点“取消付款”）' : '[[活动 › 该交易 › 取消|Activity › the transaction › Cancel]]';
  final historyBackupPlace = phone
      ? '[[设置 › 此钱包 › 导出钱包数据|Settings › This wallet › Export wallet data]]'
      : '[[设置 › 此钱包 › 导出钱包数据|Settings › This wallet › Export wallet data]]';
  final restorePlace = phone
      ? '**用助记词恢复**（在首屏或[[设置 › 此钱包|Settings › This wallet]]中）'
      : '**用助记词恢复**（在首屏、“解锁 › 添加钱包”或[[设置 › 所有钱包|Settings › All wallets]]中）';
  final recheckPlace = phone ? '[[设置 › 此钱包 › 重新核对余额|Settings › This wallet › Recheck balance]]' : '[[设置 › 重新核对余额|Settings › Recheck balance]]';
  final phrasePlace = phone ? '[[设置 › 安全 › 备份助记词|Settings › Security › Back up recovery phrase]]' : '[[设置 › 助记词|Settings › Recovery phrase]]';
  return <HelpTopic>[
    HelpTopic(
      'start',
      '接收你的第一笔 EPIC',
      '打开“接收”，复制 Epicbox 地址并发给付款方。付款会自动到账。',
      [
        HelpBlock.p('Epicbox 地址是一串长代码，以 **@** 和 Epicbox 服务器名称结尾，例如 **…@${hostSettings.epicboxUse}**。它可以放心分享：别人需要它来付款，但无法用它拿走任何东西。'),
        const HelpBlock.ol(['打开[[接收|Receive]]。', '复制地址（或显示其二维码），发给付款方。', '付款会自动出现在“活动”中。']),
        if (phone)
          const HelpBlock.p('应用打开且节点已同步时才能接收。应用关闭期间发来的付款会像放在邮政信箱里一样在 Epicbox 服务器上等待，并在下次解锁时到账。')
        else
          const HelpBlock.p('解锁后，节点同步完成即自动开始接收。如果有人付款时钱包未打开，Epicbox 会保存这笔付款，钱包在下次解锁时取回。'),
        HelpBlock.p('新付款首先要等发送方钱包完成交易，然后显示为确认中。经过 $confirmations 个确认后即可使用。'),
      ],
      id: HelpId.receive,
    ),
    HelpTopic(
      'start',
      '向他人发送',
      '打开“发送”，粘贴对方的 Epicbox 地址，输入金额，核对手续费后发送。',
      [
        HelpBlock.ol(['打开[[发送|Send]]，粘贴收款方地址，或选择一个联系人。', '输入金额。发送前会显示手续费。', phone ? '点 **继续**，检查无误后点 **发送 … EPIC**。' : '点 **确认**，检查无误后点 **发送 … EPIC**。']),
        const HelpBlock.p('此时需要收款方钱包回复（见“为什么交易需要双方参与？”）。通过 Epicbox 时，对方不必此刻在线：付款会一直等到对方钱包打开。在此期间，所用的币会被锁定，因此无法被花费两次。'),
        HelpBlock.p('收到对方回复后，钱包会自动完成付款并广播到网络。经过 $confirmations 个确认后交易即为最终。'),
        HelpBlock.p('**没有回复？** 几分钟后状态会显示“等待接收方”。请对方打开钱包。如果一直没有回复，请在 $cancelPlace 取消付款以解锁币。无人回复的付款会在大约一天后自动取消。'),
        if (phone)
          HelpBlock.p('发送需要已同步的节点。Epicbox 地址还需要 Epicbox 服务器有响应；链接地址（${tor ? 'http 或 .onion' : 'http'}）需要收款方钱包在那一刻处于打开且可访问的状态。')
        else
          HelpBlock.p('发送需要已同步的节点。Epicbox 地址还需要开启 Epicbox 接收；链接地址（${tor ? 'http 或 .onion' : 'http'}）需要收款方钱包在那一刻处于打开且可访问的状态。'),
      ],
      id: HelpId.send,
    ),
    HelpTopic(
      'start',
      '用文件发送',
      '手动方式：保存交易文件，交给收款方，然后打开对方发回的回复文件。',
      [
        const HelpBlock.p('直接 · 文件传输完成的握手与 Epicbox 相同，只是消息由人工传递，例如通过电子邮件、聊天或 U 盘。它不依赖 Epicbox，也不需要双方钱包同时在线。'),
        if (phone)
          const HelpBlock.ol(['**发送方：** 在“发送”中选择 **直接 · 文件传输**，输入金额并分享文件（以 .tx 结尾）。从此刻起币被锁定。', '**收款方：** 在[[接收 › 直接 · 文件|Receive › Direct · File]]中打开该文件。其钱包签名后分享一个回复文件（以 .response 结尾），并把该文件发回。', '**发送方：** 在[[接收 › 直接 · 文件|Receive › Direct · File]]中打开回复文件。钱包完成付款并广播。'])
        else
          const HelpBlock.ol(['**发送方：** 在“发送”中选择 **直接 · 文件传输**，输入金额并保存文件（以 .tx 结尾）。从此刻起币被锁定。', '**收款方：** 在[[接收 › 交易文件 › 签署交易文件|Receive › Transaction files › Sign a transaction file]]中打开该文件。其钱包签名后保存一个回复文件（以 .response 结尾），并把该文件发回。', '**发送方：** 在[[接收 › 交易文件 › 完成回复文件|Receive › Transaction files › Finalize a response file]]中打开回复文件。钱包完成付款并广播。']),
        const HelpBlock.p('其他 Epic Cash 钱包对这些步骤有各自的叫法。如果一直收不到回复文件，请在“活动”中取消付款以解锁币。'),
      ],
      id: HelpId.file,
    ),
    if (phone)
      const HelpTopic(
        'start',
        '当面付款：直接 · 二维码付款',
        '并排的两部手机用动态二维码付款，两者之间无需连接。',
        [
          HelpBlock.p('付款以动态二维码的形式传递，由另一部手机用摄像头扫描。内容没有加密，所以只给你要付款的人看。'),
          HelpBlock.ol(['**发送方：**在发送页选择**直接 · 二维码付款**，输入金额，点**生成付款二维码**，然后点**显示二维码**。二维码在你点显示之前一直隐藏，倒数 3、2、1，并会在 40 秒后自动隐藏。', '**接收方：**在[[接收 › 直接 · QR|Receive › Direct · QR]]点**扫描付款二维码**，接受付款，然后用同样的方式显示回复。', '**发送方：**点**扫描对方的回复**。钱包会发布付款，进度会在跟踪页显示。']),
          HelpBlock.p('请让二维码保持在取景框内，直到所有段都读完：圆环和计数显示进度。不是付款二维码的码会被忽略，并给出提示。二维码屏幕上禁止截屏。'),
        ],
        id: HelpId.qr,
      ),
    HelpTopic(
      'start',
      '付款方式与发送默认设置',
      '每种方式都是一个开关；Epicbox 默认开启。“发送”从默认方式打开。',
      [
        const HelpBlock.p('[[设置 › 交易|Settings › Transactions]]页面包含三项内容。'),
        HelpBlock.ul([
          '**付款方式。** 每种一个开关。**Epicbox** 默认开启；关闭后，钱包不连接任何服务器，因此没有 Epicbox 付款或账单，“接收”也不显示 Epicbox 地址（发到该地址的付款会在服务器上等待）。${tor ? "**链接 · HTTP**（向网址付款）、**链接 · Tor**（向 .onion 地址付款${phone ? '，以及用这部手机的 Tor 地址收款' : ''}）和${phone ? '**直接 · 二维码付款**、' : ''}**直接 · 文件传输**" : "**链接 · HTTP**（向网址付款）${phone ? '、**直接 · 二维码付款**' : ''}和**直接 · 文件传输**"}不需要 Epicbox 服务器。关闭的方式不会出现在“发送”和“接收”中。${phone ? '在手机上，**链接 · HTTP** 只在你信任的 Wi-Fi 网络上接收：在“接收”中点**信任此网络**即可添加；[[设置 › 交易|Settings › Transactions]] › **信任的网络**中可以查看并忘记它们。' : ''}',
          '**发送从哪种方式开始。** “发送”页面打开时使用的方式。在“发送”中仍可选择其他方式。',
          '**发送默认设置。** 一笔发送花掉哪些输出（“最小”或“全部”），以及找零是否拆分。只有在“高级”中开启**发送选项**时才会显示。',
        ]),
      ],
      id: HelpId.methods,
    ),
    HelpTopic(
        'start',
        '地址是什么样的',
        tor ? 'Epicbox 地址以 es 开头，以 @ 和服务器名称结尾。链接地址是网址，或以 .onion 结尾。' : 'Epicbox 地址以 es 开头，以 @ 和服务器名称结尾。链接地址是网址。',
        [
          HelpBlock.ul([
            '**Epicbox**：约 52 个字符，以 **es** 开头，然后是 **@** 和服务器，例如 **esXXXX…XXXX@${hostSettings.epicboxUse}**。默认方式；收款方可以不在线。',
            if (tor)
              '**链接 · HTTP** 和 **链接 · Tor**：收款方自己的钱包，且此刻处于打开状态。**http://host:${appConfig.httpListenPort}** 这样的网址走 链接 · HTTP；以 **.onion** 结尾、共 56 个字符的 Tor 地址走 链接 · Tor，即经由 Tor 发送。'
            else
              '**链接 · HTTP**：收款方自己的钱包，且此刻处于打开状态。**http://host:${appConfig.httpListenPort}** 这样的网址走 链接 · HTTP。',
          ]),
          HelpBlock.p('“发送”会根据粘贴到“收款方”栏中的地址选择方式。口头核对地址时，比较前六个和后六个字符。'),
        ],
        id: HelpId.addresses,
      ),
    HelpTopic(
      'how',
      '为什么交易需要双方参与？',
      '在 Epic Cash 中，收款方钱包要参与构建每一笔交易，因此双方钱包都必须参与。',
      [
        HelpBlock.p('Epic Cash 使用 Mimblewimble。它不在区块链上写入地址和金额，而是由两个钱包共同构建每笔交易，就像握手一样：'),
        HelpBlock.ol(['发送方钱包发起交易，并锁定要发送的输出。', '收款方钱包加入自己的部分并签名。', '发送方钱包也签名，完成交易并广播到网络。']),
        HelpBlock.p('需要有东西在两个钱包之间传递消息。**Epicbox** 在对方钱包离线时保存每条消息，所以双方不必同时在线。${tor ? '**链接 · HTTP** 和 **链接 · Tor**' : '**链接 · HTTP**'} 在对方钱包打开时直接送达。**直接 · 文件传输**，配合交易文件，是手动方式。'),
      ],
      handshake: true,
      id: HelpId.handshake,
    ),
    HelpTopic(
      'how',
      '确认',
      '付款经过 $confirmations 个确认后即为最终。',
      [
        const HelpBlock.p('网络接受交易后，矿工会把它打包进一个区块。包含该交易的区块是第一个确认，之后的每个区块再增加一个确认，使交易越来越难以撤销。'),
        HelpBlock.p('此钱包在 **$confirmations 个确认** 后视交易为最终。在此之前显示为 **确认中**，收到的输出暂时不能花费。这个数字可以在设置中更改：默认 6，可设为 1 到 30。确认数越少越快，但越不安全：链偶尔会替换它最新的区块（称为重组），确认数少的付款可能因此被撤销。'),
        const HelpBlock.ul(['**等待中**：两个钱包都要对付款签名。通过 Epicbox 时这会自动完成。', '**确认中**：付款已在链上，正在累积确认。', '**可用**：确认已够，币可以花费。']),
        const HelpBlock.p('比平时慢？钱包只能通过它的节点看到新区块：请检查节点是否已同步。'),
      ],
      id: HelpId.confirmations,
    ),
    HelpTopic(
      'how',
      '区块链上能看到什么',
      '没有地址，也没有金额：只有网络能够验证、却看不出是谁和多少的币记录。',
      [
        const HelpBlock.p('在许多区块链上，任何人都能查到一个地址，看到它的余额和历史。Epic Cash 不同：'),
        HelpBlock.ul(['**区块链上没有地址。** Epicbox 地址只告诉 Epicbox 把消息送到哪里，从不写入区块链。', '**区块链上没有金额。** 金额通过密码学隐藏，网络仍能验证没有凭空造出币。', '**备注不上链。** 发送时附加的消息只发给对方钱包。联系人和钱包名称保存在$device上。']),
        HelpBlock.p('没有隐藏的是：节点和 Epicbox 服务器能看到钱包的 IP 地址，公共节点能看到钱包查询了哪些输出。${tor ? 'Tor 或 VPN' : 'VPN'} 可以隐藏 IP 地址。'),
        if (tor) const HelpBlock.p('**Epicbox。** 经 Tor 时，Epicbox 服务器看不到此设备的地址。'),
      ],
      id: HelpId.privacy,
    ),
    HelpTopic(
      'how',
      '锁定金额与找零',
      '余额由一个个独立的输出组成。发送会花掉整个输出，并把剩余部分作为找零退回。',
      [
        const HelpBlock.p('余额是一组输出。要从一个 5 EPIC 的输出中发送 3 EPIC，钱包会花掉整个输出：3 EPIC 给收款方，一小笔手续费给矿工，剩余部分作为一个新输出退回，即 **找零**。'),
        const HelpBlock.p('因此，发送后的几分钟内，部分余额可能不可用：'),
        HelpBlock.ul(['**已锁定**：尚未完成的发送所用的输出。如果取消发送，它们会被解锁。', '**等待完成**：仍在等待对方钱包的交易。', '**确认中**：所在区块确认数少于 $confirmations 个的输出，包括找零。']),
        const HelpBlock.p('输出列在[[输出|Outputs]]中。'),
      ],
      id: HelpId.locked,
    ),
    HelpTopic(
      'how',
      '最小或全部：发送花费哪些输出',
      '最小（默认）使用尽量少的小额输出，其余保持可用。全部会使用每一个输出。',
      [
        const HelpBlock.p('**最小** 按金额对可用输出排序，从最小的开始取，直到覆盖金额和手续费。发送确认期间只锁定这些输出；其余可以立即发送。'),
        HelpBlock.p('**全部** 花掉每一个可用输出，并退回一个找零输出。所有资金锁定 $confirmations 个区块，钱包最终的输出更少、更大，手续费也略高，因为每个输入都有成本。发送全部余额时总是使用“全部”。'),
        if (phone)
          const HelpBlock.p('默认方式在[[设置 › 交易|Settings › Transactions]]中设置，需要在“高级”中开启“发送选项”。')
        else
          const HelpBlock.p('默认方式在[[输出 › 管理输出|Outputs › Manage outputs]]中设置；“发送”可在**发送选项**中为单次发送更改。'),
      ],
      id: HelpId.strategy,
    ),
    HelpTopic(
      'how',
      '拆分与合并',
      '拆分生成更多输出，让发送可以接连进行；合并把它们合成一个。',
      [
        HelpBlock.p('两者都是此钱包发给自己的普通网络交易，与任何发送一样在 $confirmations 个区块后确认，在此之前都会锁定所有可用输出。'),
        const HelpBlock.ul(['**拆分** 用可用余额生成 2 到 10 个金额几乎相等的输出。', '**合并** 用所有可用输出生成一个输出。', '**拆分找零**（默认开启）在普通发送中、剩余输出过少时做同样的事，每多一个输出收取 0.004 EPIC。']),
        const HelpBlock.p('“活动”中每次操作显示为两条记录：一次发送和一次接收，对方都是此钱包。两者都在[[输出 › 管理输出|Outputs › Manage outputs]]中。'),
      ],
      id: HelpId.split,
    ),
    const HelpTopic(
      'how',
      '手续费',
      '每笔交易都要支付一小笔网络手续费，发送前会显示，归矿工所有。',
      [
        HelpBlock.p('手续费取决于交易花费和生成的输出数量，与金额无关。通常只是 1 EPIC 的一小部分。'),
        HelpBlock.p('发送前显示为 **网络手续费**。金额旁的 **最大** 会填入全部可用余额减去准确的手续费，因此不会产生找零。'),
      ],
      id: HelpId.fees,
    ),
    HelpTopic(
      'safety',
      '你的助记词',
      '这些单词是找回 EPIC 的唯一方式。请抄写在纸上，切勿泄露。',
      [
        HelpBlock.p('助记词（新钱包为 24 个单词）是资金的钥匙。凭它可以在任何${phone ? '手机或电脑' : '电脑'}上恢复钱包，而任何拿到它的人都能拿走 EPIC。'),
        const HelpBlock.ul(['按顺序把单词抄写在纸上，并把纸保存在安全、离线的地方。', '切勿以照片、截图或文件形式保存。切勿在网站或聊天中输入。', 'Epic Cash 或此钱包的任何人都不会向你索要助记词。']),
        if (phone)
          HelpBlock.p('要再次查看单词，打开$phrasePlace并输入$secret。应用不会把它们发送到任何地方。最好不要复制：如果复制了，钱包会在 60 秒后，以及钱包锁定或关闭时清空剪贴板。')
        else
          HelpBlock.p('要再次查看单词，打开$phrasePlace并输入$secret。最好不要复制：如果复制了，钱包会在 60 秒后，以及钱包锁定或关闭时清空剪贴板。'),
      ],
      id: HelpId.phrase,
    ),
    if (phone)
      const HelpTopic(
        'safety',
        'PIN 码或密码短语',
        'PIN 码或密码短语用于在这部手机上解锁钱包。只有助记词能找回币。',
        [
          HelpBlock.p('PIN 码或密码短语用于在这部手机上解锁钱包；只有助记词能找回币。密码短语更长、更难猜：至少 10 个字符，不能只有数字。在[[设置 › 安全|Settings › Security]]中开启。'),
          HelpBlock.p('选择密码短语时显示的破解时间，是针对这部手机的估算。'),
          HelpBlock.p('**忘记了？** 用助记词恢复钱包，并设置一个新的。'),
        ],
        id: HelpId.passphrase,
      ),
    HelpTopic(
      'safety',
      '备份与恢复',
      '助记词就是备份。要恢复钱包，在“用助记词恢复”中输入这些单词。',
      [
        const HelpBlock.p('助记词能找回区块链上的一切，也就是余额。'),
        HelpBlock.p('**恢复方法**：在新${phone ? '手机' : '电脑'}上或丢失后，打开$restorePlace，输入单词并设置${phone ? ' PIN 码' : '密码'}。钱包打开后会扫描区块链查找自己的输出。首次扫描完成后余额才会出现；找到的付款标记为 **恢复的资金**。'),
        HelpBlock.p('**恢复无法找回的内容：** 从未上链的信息，例如谁付了什么、备注和标签、联系人、账单、设置和钱包名称。钱包数据文件会保存这些：$historyBackupPlace。${phone ? '请把该文件保存在手机以外的地方，例如电子邮件或云存储中。' : ''}'),
        const HelpBlock.p('**钱包数据文件不是助记词。** 它不含助记词，也无法单独恢复钱包。恢复时：先输入助记词，再导入该文件；恢复完成后钱包会立即提示导入。'),
        HelpBlock.p('**余额看起来不对？** 运行$recheckPlace。它会为此钱包的输出重新读取整条区块链。'),
        if (!phone)
          const HelpBlock.p('**导出 CSV** 会把付款列表保存为表格文件，文件名为 **epic-payments-<钱包>-<日期>.csv**，列包括日期、类型、状态、金额、手续费、对方、备注、slate ID、kernel 和区块高度。文件没有加密：任何拿到它的人都能读到金额、日期、地址和备注。它不能再导入；导入请用**导出钱包数据**。'),
        if (!phone)
          const HelpBlock.p('**钱包文件** 位于[[设置 › 此钱包 › 钱包文件夹|Settings › This wallet › Wallet folder]]。即使有这些文件的副本，也请保留助记词：文件丢失时它仍然有效。'),
      ],
      id: HelpId.backup,
    ),
    const HelpTopic(
      'safety',
      '导入之前',
      '导入只会读取旧钱包和文件。请先为每个钱包做好备份；导入的风险由你自行承担。',
      [
        HelpBlock.p('这是一个新应用的早期版本。'),
        HelpBlock.p('导入只会读取你的旧钱包和文件，绝不会删除或更改它们。'),
        HelpBlock.p('继续之前，请确认每个钱包都有备份：它的助记词，以及你保留的钱包文件。'),
        HelpBlock.p('导入的风险由你自行承担，任何损失概不负责。'),
      ],
      id: HelpId.importWarning,
    ),
    HelpTopic(
      'network',
      phone ? '节点' : '节点：公共节点或本地节点',
      phone
          ? '节点把钱包连接到 Epic Cash 网络。钱包使用公共节点；节点落后时请换一个。'
          : '节点把钱包连接到 Epic Cash 网络。公共节点最快捷；本地节点归你自己。',
      [
        const HelpBlock.p('钱包需要节点来读取区块链（余额和确认），并把交易广播到网络。'),
        if (phone)
          HelpBlock.p('**公共节点** 是由他人运行的节点之一，可以立即使用。其运营者能看到钱包的 IP 地址以及它查询了哪些输出${tor ? '；Tor 可以隐藏该地址' : ''}。')
        else
          const HelpBlock.ul(['**公共节点**（默认）：由他人运行的公共节点之一，可以立即使用。其运营者能看到钱包的 IP 地址以及它查询了哪些输出。', '**本地节点**：在这台电脑上作为独立程序运行，随应用启动和停止。它首先要下载整条链（第一次约 4 GB，之后每天一点点），需要一些时间；在磁盘上约占 5 GB，并缓慢增长。同步期间，钱包会显示进度并使用公共节点。见“运行本地节点”。']),
        if (phone)
          HelpBlock.p('点“钱包”标签页上的节点图标，或在$nodePlace中更换：节点会连同状态一起列出。点一个即可立即切换到它，也可以输入地址来筛选列表或添加节点。发送需要已同步的节点；显示 **落后 {n}** 或 **无响应** 时，请换一个。')
        else
          HelpBlock.p('在$nodePlace中更换：节点会连同状态一起列出。点击一个即可立即切换到它，也可以输入地址来筛选列表或添加节点。发送需要已同步的节点；如果节点落后，钱包会推荐另一个。'),
      ],
      id: HelpId.node,
    ),
    if (!phone)
      HelpTopic(
        'network',
        '运行本地节点',
        '在这台电脑上运行的节点的端口、对等节点、链数据和所有者访问。',
        [
          HelpBlock.p('本地节点是随应用附带的独立程序。它有自己的链副本，所以钱包不必询问别人。它在磁盘上约占 5 GB 并缓慢增长；第一次下载约 4 GB，之后每天一点点。同步完成之前，无法通过它发送或接收，钱包可以暂时使用公共节点。'),
          HelpBlock.ul([
            '**随应用启动** 会在应用启动时启动节点，并在应用打开期间保持同步。应用关闭时它会停止。',
            '**端口。** API 端口（3413）是钱包与节点通信用的；P2P 端口（3414）是其他节点连接这个节点用的。只有在这台电脑或这个网络上的另一个节点已在使用它们时才需要更改。节点会用新端口重启。',
            '**对等节点。** 节点会自己寻找对等节点。首选对等节点最先加入。最大入站数和最大出站数取 8 到 500 之间的数。可以在“对等节点”标签页中封禁和解封对等节点。',
            '**链数据。** **使用已有数据** 让节点读取其他 Epic 节点留在这台电脑上的链数据，而不是重新下载；不会复制任何内容，该文件夹的“删除链数据”也会关闭。**删除** 会清除这个节点的链数据；下次启动时整条链会重新下载。密钥和历史记录不受影响。',
            '**所有者访问。** 同步阶段和对等节点来自节点的所有者 API。它的密钥是节点数据文件夹中 **.api_secret** 文件的第一行。钱包把密钥保存在这台电脑的密钥环中，从不放进设置或钱包数据文件。对另一台电脑上的节点，密钥通过 http 明文传输，在该网络上可被读取：在共享网络中请使用 VPN 或 https。',
          ]),
        ],
        id: HelpId.localNode,
      ),
    HelpTopic(
      'network',
      'Epicbox',
      'Epicbox 在钱包之间传递交易，并在对方钱包离线时保存它们。',
      [
        const HelpBlock.p('每笔交易都有双方钱包参与，因此它们的消息需要一个汇合点。Epicbox 服务器就是这个汇合点：它保存发给此钱包的付款，直到钱包上线，并把钱包的回复送回去。消息是加密的，Epicbox 无法花费这些币。'),
        const HelpBlock.p('Epicbox 地址是钱包的公钥，后接 **@** 和其 Epicbox 服务器的名称。'),
        if (phone)
          HelpBlock.p('点“钱包”标签页上的 Epicbox 图标，或在$epicboxPlace中设置服务器：服务器会连同状态一起列出。点一个并确认，也可以输入地址来筛选列表或添加服务器。更换服务器会改变 @ 之后的部分，因此请把新地址告诉付款方。其他 Epic Cash 钱包也使用 Epicbox；两个钱包可以使用不同的服务器。')
        else
          HelpBlock.p('在$epicboxPlace中设置服务器：服务器会连同状态一起列出。点击一个并确认，也可以输入地址来筛选列表或添加服务器。更换服务器会改变 @ 之后的部分，因此请把新地址告诉付款方。其他 Epic Cash 钱包也使用 Epicbox；两个钱包可以使用不同的服务器。'),
      ],
      id: HelpId.epicbox,
    ),
    if (tor && phone)
      HelpTopic(
        'network',
        'Tor',
        '一个开关即可让钱包的连接经由 Tor，并为其提供 .onion 地址。更慢，但更私密。默认关闭。',
        [
          HelpBlock.p('Tor 向钱包所连接的服务器隐藏其 IP 地址。打开$torPlace中的开关后，Epicbox 连接经由 Tor，发往 .onion 地址的付款经由 Tor，钱包还会拥有自己的 Tor 地址（以 .onion 结尾），其他钱包可以直接向它付款。'),
          const HelpBlock.ul([
            '节点、Epicbox 服务器和地址都保持不变。',
            '发往 onion 地址的链接付款经由 Tor；“发送”会显示付款是否经由 Tor。',
            '比不使用 Tor 慢。某些国家封锁了 Tor；在那里它无法连接。',
            '应用打开时可以通过 .onion 地址接收；Epicbox 同时照常工作。',
            '网络模式为“仅 Tor”时，开关保持开启，无法关闭。',
          ]),
          const HelpBlock.p('**正在启动…** 表示 Tor 正在连接；受其覆盖的连接会等待，绝不绕过它。**未连接** 表示连接失败：点“重试”，或关闭 Tor。有些钱包显示的 Tor 地址不带 .onion；两者是同一个地址。'),
        ],
        id: HelpId.tor,
      )
    else if (tor)
      const HelpTopic(
        'network',
        'Tor',
        '更慢，但更私密：一个开关即可让钱包的连接经由 Tor，无需开放端口。默认关闭。',
        [
          HelpBlock.p('开启 Tor 后，与 Epicbox 服务器的连接经由 Tor，钱包还会拥有一个 Tor 地址（以 .onion 结尾），其他钱包可以从任何地方直接向它付款，无需在路由器上做端口转发。开启 Tor 不会改变你分享的地址。'),
          HelpBlock.ul([
            '在[[设置 › 网络与隐私 › Tor|Settings › Network & privacy › Tor]]中开启。侧边栏中的 Tor 行显示其状态。',
            'Tor 启动中或未连接时，经由 Tor 的内容会等待；不会绕过它。点“重试”，或关闭 Tor。',
            '链接 · HTTP 发往 http(s) 地址时不经由 Tor；“发送”会注明这一点。',
            'Tor 开启期间 链接 · HTTP 接收关闭：其他钱包直接发来的付款会到达 链接 · Tor 地址。',
            '某些国家封锁或不允许使用 Tor；在那里它无法连接。',
            '网络模式为“仅 Tor”时，开关保持开启，无法关闭。',
          ]),
          HelpBlock.p('有些钱包显示的地址不带 .onion；两者是同一个地址。'),
        ],
        id: HelpId.tor,
      ),
    HelpTopic(
      'network',
      '网络模式',
      tor
          ? '常规、仅 Tor、仅节点或紧急断网：各自连接什么，以及如何用一个从不联网的钱包付款。'
          : '常规、仅节点或紧急断网：各自连接什么，以及如何用一个从不联网的钱包付款。',
      [
        HelpBlock.p('钱包使用多少互联网，是 $netPlace 中的一个选择，钱包会记住它。离开**常规**模式后，${phone ? '主页' : '标题栏'}上的标记会写出当前模式；点它即可更改。'),
        HelpBlock.ul([
          tor
              ? '**常规**：钱包设置的一切：节点、Epicbox、链接、状态站点、价格和更新检查。Tor 是 $torPlace 中的独立开关。'
              : '**常规**：钱包设置的一切：节点、Epicbox、链接、状态站点、价格和更新检查。',
          if (tor)
            '**仅 Tor**：所有连接都经过 Tor，包括节点和 Epicbox；任何内容都不会接触公开互联网。Tor 就绪之前什么都不会连接，状态图标会写**等待 Tor**。链接 · HTTP 收款保持关闭：明文地址会暴露这台设备。',
          '**仅节点**：钱包只与正在使用的节点通信，即节点列表中的第一个。Epicbox、链接、状态站点、价格、更新检查、浏览器链接、问题报告、配对和已关联设备都已关闭。${phone ? '**直接 · 二维码付款**和**直接 · 文件传输**' : '**直接 · 文件传输**'}可用。${tor ? '开启 Tor 时，节点通过 Tor 连接。' : ''}',
          '**紧急断网**：什么都不连接，节点也不例外。钱包会以上次已知的余额和历史记录打开。你可以通过${phone ? '**直接 · 文件传输**和**直接 · 二维码付款**' : '**直接 · 文件传输**'}创建、签署并完成付款，显示你的地址，备份和导出。等待接收方的付款会暂停，离开该模式后继续。',
        ]),
        const HelpBlock.h('为什么“仅节点”最好用自己的节点', anchor: HelpAnchor.ownNode),
        HelpBlock.p('正在使用的节点会看到钱包发出的每个请求。位于$device或你网络中的节点会把这些留给你自己，而且响应很快。任何节点都可以。请在 $nodePlace 中选择。'),
        const HelpBlock.h('在“紧急断网”下付款', anchor: HelpAnchor.coldStorage),
        HelpBlock.ol([
          '像平常一样通过${phone ? '**直接 · 文件传输**或**直接 · 二维码付款**' : '**直接 · 文件传输**'}创建付款，回复回来后完成它。',
          '钱包会显示**已完成，未广播**：付款是完整的，但只有联网的设备才能广播它。',
          '**保存文件**，并${phone ? '**显示二维码**' : '**复制**文本'}，然后带到联网的设备上。',
          '在那里${phone ? '在“活动”菜单中选择**广播已完成的付款**' : '在“接收”的“交易文件”中选择**广播已完成的付款**'}，载入文件${phone ? '或扫描二维码' : '或粘贴文本'}，然后按**广播**。任何 Epic Cash 钱包都可以做到；不需要密钥。',
          '回到这里，付款会显示**待在其他设备广播**；离开“紧急断网”后，钱包在链上看到它，就会显示**确认中**。',
        ]),
        HelpBlock.p('被模式关闭的服务会显示为灰色的**关闭（仅节点）**：这是模式，不是错误。切换时不会取消任何内容；通过 Epicbox 等待接收方的付款会在你离开该模式后继续${tor ? '（或切换到“仅 Tor”）' : ''}。'),
        HelpBlock.p('**节点故障切换**默认开启。当你的节点 30 秒没有响应时，钱包会改用列表里下一个可用的节点，只在本次会话中有效：你自己的节点仍然保存着，下次启动时，或者你自己选择节点后，钱包就会回到它。在“仅节点”和“紧急断网”下它从不切换${phone ? '' : '，也不会离开这台电脑上的节点'}${tor ? '；选择“仅 Tor”时，它只切换到可通过 Tor 访问的节点' : ''}。'),
      ],
      id: HelpId.modes,
    ),
    HelpTopic(
      'network',
      '高级',
      '一开始全部关闭。每个开关会在相应位置显示钱包的另一部分。',
      [
        const HelpBlock.p('**高级**是设置中的一个页面，放着大多数人用不到的功能。其中一切一开始都是关闭的，让钱包保持简单。开关会把对应部分加到它所属的位置，**再次全部隐藏**则把它们全部关闭。'),
        HelpBlock.ul([
          '**输出**：“输出”页面，列出组成余额的币，以及你可以对它们做的操作。',
          '**技术详情**：${phone ? '付款详情' : '交易'}中的 slate ID、内核、承诺和区块高度。不开启时，交易上的**更多**链接可以一次性显示它们。',
          if (phone)
            '**发送选项**：“策略”和“拆分找零”，在[[设置 › 交易|Settings › Transactions]]中：一笔发送花掉哪些输出，以及找零是否拆分。'
          else
            '**发送选项**：“发送”中的一个折叠区，单笔发送可在其中选择“最小”或“全部”，以及是否拆分找零。',
          '**服务器详情**：节点和 Epicbox 列表以及状态卡片中的主机、延迟、版本和区块高度。',
          if (phone)
            '**从某个高度重新核对**：让“重新核对余额”可以从某个区块高度或日期开始，而不是从第一个区块开始。恢复钱包时始终可以选择。'
          else
            '**从某个高度重新核对**：让“重新核对余额”同时丢弃未确认的交易。恢复钱包时会向所有人提供起始区块。',
          if (!phone) '**本地节点**：让这台电脑运行自己的节点，在$nodePlace中。',
          if (!phone) '**日志**：“帮助”中的“日志”分组，用于打开日志文件夹或清除日志。无论是否开启，“报告问题”都会附上日志。',
        ]),
        const HelpBlock.p('**确认数** 决定收到的付款要等待多少个区块，其输出才能花费：默认 6，可设为 1 到 30。确认数越少越快，但越不安全。'),
        const HelpBlock.p('**实验性** 包含 **账单**，一开始是关闭的：已配对联系人之间的付款请求和账单。关闭时它们被隐藏，也不会为其检查任何内容。配对本身始终开启。'),
        HelpBlock.p('网络模式和**节点故障切换**都在 $netPlace 中：见“网络模式”。'),
      ],
      id: HelpId.advanced,
    ),
    HelpTopic(
      'trouble',
      '故障排除',
      phone
          ? '大多数问题是节点仍在同步，或收款方尚未回复。'
          : '大多数问题是节点仍在同步、收款方尚未回复，或端口被占用。',
      [
        if (phone)
          const HelpBlock.p('**“节点未同步”：无法发送。** 节点追上网络后即可发送。请稍等，或点“钱包”标签页上的节点图标，选择另一个节点。')
        else
          const HelpBlock.p('**“节点未同步”：无法发送。** 节点追上网络后即可发送。请稍等，或在[[设置 › 节点|Settings › Node]]中选择另一个节点。'),
        if (phone)
          const HelpBlock.p('**“Epicbox 无响应”。** 钱包无法连接到它的 Epicbox 服务器。请稍等；如果一直如此，请检查网络连接，或点“钱包”标签页上的 Epicbox 图标，选择另一个服务器。在此期间可以使用 直接 · 文件传输。')
        else
          const HelpBlock.p('**“Epicbox 无响应”。** 钱包无法连接到它的 Epicbox 服务器。请稍等；如果一直如此，请检查网络连接，或在[[设置 › 交易|Settings › Transactions]]中选择另一个服务器。在此期间可以使用 直接 · 文件传输。'),
        const HelpBlock.p('**发送显示“等待接收方”。** 对方钱包尚未回复。请对方打开钱包。如果对方一直不会打开，请在“活动”中取消付款以解锁币。'),
        if (phone)
          const HelpBlock.p('**付款没有到账。** 查看“钱包”标签页上的状态图标：节点已同步、Epicbox 已连接。更换 Epicbox 服务器后，发送方需要新地址。发送方钱包还必须完成交易；之后还需几分钟进行确认。')
        else
          const HelpBlock.p('**付款没有到账。** 在“接收”中检查接收是否已开启、节点是否已同步。更换 Epicbox 服务器后，发送方需要新地址。发送方钱包还必须完成交易；之后还需几分钟进行确认。'),
        if (phone && tor)
          const HelpBlock.p('**Tor 显示“未连接”。** Tor 无法连接到其网络。在[[设置 › 网络与隐私|Settings › Network & privacy]]中点“重试”，或关闭 Tor；在此期间不会发出任何内容。'),
        if (!phone) ...[
          HelpBlock.p('**“端口 ${appConfig.httpListenPort} 已被其他程序占用”。** 另一个程序（通常是另一个 Epic 钱包）正在使用该端口进行 链接 · HTTP 付款。关闭它，然后在“接收”中点“重试”。在此期间 ${tor ? 'Epicbox、链接 · Tor 和 直接 · 文件传输' : 'Epicbox 和 直接 · 文件传输'}照常工作。'),
          const HelpBlock.p('**“另一个 Epic 程序正在使用此文件夹”。** 另一个 Epic 钱包或节点打开了相同的文件。关闭它后重试。'),
        ],
        if (phone)
          const HelpBlock.p('**忘记 PIN 码。** 在解锁界面删除钱包，然后用助记词恢复并设置新的 PIN 码。没有助记词，EPIC 将无法找回。')
        else
          const HelpBlock.p('**“密码错误”。** 检查大写锁定键和键盘布局。如果忘记了密码：用助记词恢复钱包并设置新密码。'),
        HelpBlock.p(tor
            ? '**某个操作是灰色的，并写出某个模式或“等待 Tor”。** $netPlace 中开启了“仅 Tor”、“仅节点”或“紧急断网”。请在那里把模式改回“常规”，或等待 Tor 连接。'
            : '**某个操作是灰色的，并写出某个模式。** $netPlace 中开启了“仅节点”或“紧急断网”。请在那里把模式改回“常规”。'),
        HelpBlock.p('**余额看起来不对。** 运行$recheckPlace。'),
      ],
      id: HelpId.trouble,
    ),
    const HelpTopic(
      'trouble',
      '另一个钱包的付款',
      '本钱包自己没有发出或收到的付款：同一助记词正在另一个钱包中使用。',
      [
        HelpBlock.p('标有**从另一台设备发送**或**由另一台设备收到**的一行，是使用相同助记词的另一个钱包的付款。区块链显示这些币已被花掉或收到，所以本钱包列出了它。'),
        HelpBlock.p('金额是已扣除找回找零后离开本钱包的数额，或收到的数额。这里不知道对方和手续费。'),
        HelpBlock.p('**如果你没有用这个助记词的其他钱包**，请先问另一个节点：切换到另一个节点并使用“重新核对余额”。节点在回答中漏掉某些币时，会让它们看起来已被花掉。如果仍显示已花掉，可能有别人知道助记词：请把 EPIC 转到使用新助记词的新钱包。'),
        HelpBlock.p('**发送失败并提示“节点显示这些币已被花掉，而本钱包没有花它们。很可能是另一个使用你助记词的钱包花掉的。”**时，该发送已被释放。钱包会刷新；余额正确后再发送。'),
      ],
      id: HelpId.otherWallet,
    ),
    HelpTopic(
      'trouble',
      '取消付款',
      '何时取消一定成功，何时不一定，以及币会怎样。',
      [
        const HelpBlock.p('取消会停止尚未完成的付款。它是否一定成功，取决于一件事：对方是否已经拥有完成这笔付款所需的一切。如果没有，取消一定成功：没有这个钱包付款就无法完成，取消也不收手续费。如果有，对方仍可能完成付款，钱包会提供两种取消方式。'),
        const HelpBlock.h('把币转回，还是解锁', anchor: HelpAnchor.twoWays),
        const HelpBlock.p('**把币转回**会先把币移回这个钱包，需支付正常的网络手续费；之后旧的付款再也无法完成。**解锁币**免费，也不移动任何币：这些币可以再次使用，付款则保持原样。如果对方仍完成了它，会显示为已付；如果没有，就什么也不会发生。'),
        const HelpBlock.h('发送', anchor: HelpAnchor.sending),
        const HelpBlock.p('从这个钱包发出的付款先等待对方回复。等待期间，取消一定成功：没有这个钱包，任何付款都无法完成，币会立刻解锁。不收手续费。对方钱包可能仍显示这笔付款在等待，但无法完成它。'),
        HelpBlock.p('收到回复后，这个钱包会一步完成付款并广播到网络。已到达网络的付款无法取消、撤销或退款；只有接收方能把钱付回来。如果网络没有接受它，付款仍然是完整的，之后仍可能完成。${phone ? '大约一天后，钱包会提供“释放资金”，同样有两种方式：把币转回把币移回这个钱包，需支付正常的网络手续费；解锁币免费。' : '钱包会提供再次广播或取消。这种取消会先检查网络，如果网络已有这笔付款则拒绝。否则它提供同样的两种方式：把币转回把币移回这个钱包，需支付正常的网络手续费；解锁币免费。'}'),
        const HelpBlock.p('一直没有回复的付款会在大约一天（1,440 个区块）后自动取消，币会解锁。Epicbox、Link 和直连付款都一样：在对方的回复进入这个钱包之前，取消一定成功。'),
        HelpBlock.p('**发送看起来卡住了。** 通常是对方钱包离线。等一等，或在 $cancelPlace 取消后重新发送。已取消的付款之后无法再完成。'),
        const HelpBlock.h('接收', anchor: HelpAnchor.receiving),
        const HelpBlock.p('付款到达时，这个钱包会立即回复，它的币都不会被锁定。此后由付款方的钱包完成并广播，通常只需几分钟。取消在 15 分钟内不可用；在付款方报告已广播期间也不提供。'),
        const HelpBlock.p('之后，取消会清除付款方始终没有广播的付款。它不一定成功：钱包会先检查网络，如果付款已在网络中则拒绝。已取消的付款仍会被关注。如果付款方之后广播了，它仍会到达并显示为已收到。'),
        const HelpBlock.h('账单（实验性）', anchor: HelpAnchor.requests),
        const HelpBlock.p('从这个钱包发出的账单在被支付之前不持有任何币。在此之前可以随时撤回：付款方将无法再支付，也没有币移动。无人支付的账单在 24 小时后过期。以二维码展示的账单只能支付一次；第二次扫描会被拒绝，所以不会重复付款。'),
        const HelpBlock.p('从这个钱包支付的账单则相反：对方已经拥有完成这笔付款所需的一切。取消会在账单时限到期时出现，大约在付款一天后，或在对方提前撤回时更早出现。它提供同样的两种方式：把币转回把币移回这个钱包，需支付正常的网络手续费，旧的付款就无法再完成；解锁币免费，把付款留给对方。如果币没有立即移回成功，钱包会在打开期间重试。在此之前对方仍可能完成付款，若完成则显示为已付。'),
      ],
      id: HelpId.cancel,
    ),
    if (!phone)
      const HelpTopic(
        'maintenance',
        '清理旧的钱包文件夹',
        '“从列表中移除”会把钱包的文件夹留在磁盘上。文件夹需手动删除，前提是已抄写助记词或钱包已空。',
        [
          HelpBlock.ul([
            '[[设置 › 所有钱包|Settings › All wallets]] 中的 **从列表中移除** 会把钱包从列表中去掉。其文件夹仍留在磁盘上，页面会在 **已从列表中移除** 下再次列出它。',
            '**删除没有助记词的钱包文件夹，会失去其中的 EPIC。** 只删除已抄写助记词的钱包，或已空且不再需要的钱包。',
            '文件夹位于数据文件夹的 **wallets** 下（[[设置 › 此钱包 › 应用文件|Settings › This wallet › App files]] 旁的 **打开文件夹**），每个钱包一个，以其 ID 命名；里面的 **WALLET.txt** 写有钱包名称。关闭 Epic Cash Desktop 后，只删除这一个 ID 文件夹，其余保持原样。',
          ]),
        ],
        id: HelpId.cleanup,
      ),
    HelpTopic('maintenance', '设置文件', '一个文件保存你的节点和 Epicbox 服务器列表。文件出错不会丢掉上一次可用的设置。', [
      if (phone) ...[
        HelpBlock.p(
          '应用保存一个文件，其中有你的节点和 Epicbox 服务器列表，以及三个开关：状态网站、更新检查和价格。其余设置随应用提供。该文件在应用中修改，例如在 $nodePlace 和 $epicboxPlace，不用手动编辑。',
        ),
        HelpBlock.ul([
          '**每个列表的第一个服务器就是正在使用的。**选择某个服务器会把它移到最上面；调整顺序会改变正在使用的服务器。第一个节点没有响应时，会尝试下一个。',
          '**第一个 Epicbox 服务器出现在每个钱包的 Epicbox 地址中。**把另一个移到最上面，每个钱包都会得到新地址；发到旧地址的付款不会到账。',
          '**无法读取的文件：**继续使用上一次可用的设置。应用写入新文件之前，会把旧文件另存为 **settings.toml.bad-<time>**。',
          '被删除的文件会重新写出。',
        ]),
      ] else ...[
        HelpBlock.p(
          '文件 **settings.toml** 保存你的节点和 Epicbox 服务器列表，以及三个开关：状态网站、更新检查和价格。其余设置随应用提供。它位于数据文件夹：Linux 和 macOS 上是 **~/.epic_cash_desktop/settings.toml**，Windows 上是 **%USERPROFILE%\\.epic_cash_desktop\\settings.toml**（**打开文件夹**，在 [[设置 › 此钱包 › 应用文件|Settings › This wallet › App files]] 旁）。',
        ),
        HelpBlock.ul([
          '在应用中所做的更改会立即写入文件。在文件中保存的更改，会在应用运行时片刻后生效。',
          '**每个列表的第一个服务器就是正在使用的。**选择某个服务器会把它移到最上面；调整顺序会改变正在使用的服务器。第一个节点没有响应时，会尝试下一个。',
          '**第一个 Epicbox 服务器出现在每个钱包的 Epicbox 地址中。**把另一个移到最上面，每个钱包都会得到新地址；发到旧地址的付款不会到账。',
          '**文件出错时：**继续使用上一次可用的设置，通知会指出出错的行，出错的文件绝不会被覆盖。',
          '如果文件有错而应用必须写入，会先把该文件另存为 **settings.toml.bad-<time>**，再写入一个正确的文件。',
          '被删除的文件会重新写出。',
        ]),
      ],
    ], id: HelpId.settingsFile),
    ...deviceHelpTopics('zh', phone: phone),
  ];
}
