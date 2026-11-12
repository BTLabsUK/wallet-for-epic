# Designer-frame visits

The phone redesign is checked against the designer's frames (390 x 844, drawn in
`~/bt-wallet-design/canvas/project/<Frame>.dc.html` with `wallet.css`). The screenshot tour
renders the app at the same size (780 x 1688 shots, view padding 54 top and 34 bottom), dark
theme only, on the frames' sample wallet. A visit is named `fr-<Frame>`.

## Run

One visit, shot to `$OUT/fr-Home-dark.png`:

    cd app && . ../tools/env.sh
    TOUR_SHOTS_OUT=$OUT build-slot flutter test tool/screenshot_tour_test.dart \
      --plain-name 'fr-Home (dark)'

One area (a regex over the test name, which is `dark fr-<Frame> (dark)`):

    TOUR_SHOTS_OUT=$OUT build-slot flutter test tool/screenshot_tour_test.dart \
      --name 'fr-(Home|Home-busy|Contacts|Contact-Tom) \(dark\)'

Compare with the frames (writes `<out>/<Frame>.png`, side by side with a difference, and `scores.txt`):

    python3 -I ../design-kit/tools/fidelity.py $OUT $COMPARE Home Contacts

## Where things are

| File | Holds |
| --- | --- |
| `frame_data.dart` | the sample wallet (names, amounts, dates), the clock (`frameNow`, Thursday 12 November 2026, 14:52), the rate, `frameSession(visit)` |
| `frames_<area>.dart` | the visits of an area (`('fr-<Frame>', _Start.home, visit)`) and its seeds |

Add a frame: one entry in the area's list, and a seed in the area's map when the frame needs
data on top of the base wallet (the seed gets the `FakeWalletSession`). Keep the frame's exact
words in the data; the app's own words stay the app's.

## Data and clock

* The clock provider is `frameNow`; a direct `DateTime.now()` in a widget is not covered.
* The rate is 1.0329999 USD per EPIC: 1,284.7321 EPIC shows `≈ $1,327.13`.
* Contacts: Northwind Exchange, Anna Kowalska, Tom, Coffee Corner, Bob, Mira Novak.

## CSS to kit

| wallet.css | Kit |
| --- | --- |
| `.w` 390 wide, Inter 15 / 1.3, tnum + cv11 | `KitType.body`, `interFeatures` |
| `.bar` 44 high, 16 in, gap 10 | `_HomeHeader` (`home_tab.dart`) |
| `.pill` 32 high, padding 0 13 0 11, gap 8, 13/500 | `KitStatusPill`, `KitType.pill` |
| `.dot` 7 + 3 halo | `KitConnectionDot` |
| `.lbl` 13 dim, 14 eye, gap 6 | `_Balance` caption, `KitIcons.eye` |
| `.amt` Montserrat 600 50, -.03em; `i` at .42; `u` 12, .16em, gold | `KitType.homeBalance`, `_Figure`, `KitType.unit` |
| `.fiat` 15 dim, margin 8 | `_Balance`, `phoneFiat` |
| `.chip` 28 high, 12.5/500 | `KitChip`, `KitType.chip` |
| `.btn` 52 high, radius 16, 16/600, gap 8 | `KitButton`, `Kit.rButton` |
| `.pair` gap 10, padding 0 16 | `_Balance` button row |
| `.sec` padding 0 18 0 16, 10 below, h2 18/600 -.015em, tick 12 x 2 | `KitSectionHead`, `KitType.sectionHead` |
| `.grp` radius 20, fill `--s1` at .92, margin 0 16 | `KitGroup`, `Kit.rGroup` |
| `.row` padding 10 14, min 62, divider from 66 | `KitRow`, `PhoneTxRow`, `Kit.dividerInsetList` |
| `.av` 40, radius 13, initials 13/600 | `KitAvatar`, `Kit.avatar`, `Kit.rAvatar` |
| `.dir` 19 round on the group ground, arrow 11 | `KitAvatar` badge, `Kit.avatarBadge` |
| `.tabs` 86 high, blur, hair top | `KitTabBar`, `Kit.tabBar` |
| `.tab` 24 icon, gap 4, 10.5/500 | `KitTabBar` tab, `KitType.tabLabel` |
| `.scan` 50 x 50, margin 10 | `KitTabBar` scan button, `Kit.scanButton` |
| `.ib` 44 round-rect icon button, filled gold variant | `KitIconButton` |
| `.chip` + `.chips` gap 8, ring 13 / lock 12 | `KitChip` (`iconSize`, `semanticsLabel`), `PhoneProgressMark` |
| `.need.brk` margin 0 16, padding 14, radius 20, `.acts` padding-left 52 gap 8, `.btn.sm` 36 | `KitNeedsYouCard`, `KitCornerMarks`, `KitButton(small)` |
| dots 4 x 4, active 14 x 4, gap 5, 12 above | `KitPageDots` |
| `.tab .bdg` 17 high, 6 right of the tab's centre | `KitTabBar` badge |
| `.ttl` 44 tall at 58 from the top, padding 0 10 0 16 | `KitTabTitle` (Contacts, Activity, Settings) |
| Contacts `.row` (name, status line, amount and time) | `ContactActivityRow` (`contact_activity_row.dart`) |
| contact page `.nav` 48, 50 from the top, back 24 + 16, `.ib` 40 | `_TopBar`, `_MoreMark` (`contact_page.dart`) |
| contact page `.av` 56 radius 18, h1 22, `.seal` 11 | `_FaceAvatar`, `_Header`, `Epic1Glyph(14)` |
| `.day` 12 faint, 14 above 8 below | `_Payments`, `_bubbleDay` |
| `.bub` max 268, radius 20 with a 7 tail, `.a` mono 21, `.s` 12.5 | `_PaymentBubble` |
| `.steps` 8 px dots, gap 7 and 9 | `_BubbleSteps`, `_StepDot` |
| `.act` padding 12 16 34, gap 10 | contact page `bar()` |
| `.w::before` gold pool + 28 px grid | `ProtocolBackdropPainter` (`theme/brand.dart`) |

Where a target must stay 48 tall for touch (the eye, "See all", the pill) the layout keeps the
frame's visual size: the taller box is offset or the space around it gives back the extra.
