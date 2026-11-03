# SPDX-License-Identifier: Apache-2.0
# G4 update trust, Windows: the rig side. Runs as the rig session's user (epicrig; scheduled task
# EpicWalletRig<k>, Windows session 0, a window station of its own) for one whole run, because a later
# rig job cannot see an earlier job's windows. Takes commands from <run>\cmd\*.json (oldest first), answers in <run>\res\<same name>.json,
# until "quit", <run>\stop, or no command for -IdleMin minutes. Everything it starts or installs lives
# under <run> (the app's USERPROFILE is <run>\home, so its data folder and its per-user install are
# there); on the way out it stops those processes. Never touches anything outside its session's <work>\trust.
#
# The app's window is never shown on this station. Posted mouse messages and WM_CHAR reach
# FLUTTERVIEW; nothing can be read back from the screen (UIA is off in Flutter's Windows engine, the
# MSAA root fails with CO_E_NOTINITIALIZED, PrintWindow captures one colour), so the driver reads the
# app's files instead. Posted Ctrl/Shift do not count (Flutter syncs modifiers from the real key
# state): only plain keys.
#
# Also runs the loopback stand-ins for the user's own servers (as standin.py does on Linux): a node
# on http://127.0.0.1:<port> forwarding to an https node, a relay on 127.0.0.1:<port> piped into TLS.
param([string]$Run, [int]$IdleMin = 45)
$ErrorActionPreference = 'Stop'
if ($Run -notmatch '^C:\\EpicRig\d?\\trust\\runs\\[^\\]+$') { throw "run folder $Run is not under C:\EpicRig<k>\trust\runs" }
$cmdDir = Join-Path $Run 'cmd'
$resDir = Join-Path $Run 'res'
$home_ = Join-Path $Run 'home'
New-Item -ItemType Directory -Force $cmdDir, $resDir, $home_ | Out-Null
$alog = Join-Path $Run 'agent.log'
function Rep([string]$s) { Add-Content -LiteralPath $alog -Value "$((Get-Date).ToString('HH:mm:ss.fff')) $s" }
Rep "agent start user=$env:USERNAME pid=$PID session=$((Get-Process -Id $PID).SessionId) run=$Run"
$env:USERPROFILE = $home_
$uk = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{8810835E-6EE5-4989-AE20-C0D60E23800E}_is1'

Add-Type -TypeDefinition @'
using System; using System.Text; using System.Collections.Generic; using System.Runtime.InteropServices;
using System.Net; using System.Net.Sockets; using System.Net.Security; using System.Net.Http; using System.IO; using System.Threading;
public static class TR {
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc f, IntPtr l);
  [DllImport("user32.dll")] static extern bool EnumChildWindows(IntPtr p, EnumProc f, IntPtr l);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassNameW(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  [DllImport("user32.dll")] static extern uint MapVirtualKey(uint code, uint type);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }

  static string Cls(IntPtr h) { var c = new StringBuilder(256); GetClassNameW(h, c, 256); return c.ToString(); }
  static string Txt(IntPtr h) { var c = new StringBuilder(512); GetWindowTextW(h, c, 512); return c.ToString(); }

  /// Top-level windows of these processes: "hwnd|pid|class|title|w|h".
  public static List<string> Windows(int[] pids) {
    var set = new HashSet<uint>(); foreach (var p in pids) set.Add((uint)p);
    var o = new List<string>();
    EnumWindows((h, l) => { uint id; GetWindowThreadProcessId(h, out id);
      if (set.Contains(id)) { RECT r; GetWindowRect(h, out r); o.Add(h.ToInt64() + "|" + id + "|" + Cls(h) + "|" + Txt(h) + "|" + (r.R - r.L) + "|" + (r.B - r.T)); }
      return true; }, IntPtr.Zero);
    return o;
  }
  public static IntPtr Child(IntPtr parent, string cls) {
    IntPtr f = IntPtr.Zero;
    EnumChildWindows(parent, (h, l) => { if (Cls(h) == cls) { f = h; return false; } return true; }, IntPtr.Zero);
    return f;
  }
  public static int[] Client(IntPtr h) { RECT r; GetClientRect(h, out r); return new[] { r.R - r.L, r.B - r.T }; }

  static IntPtr XY(int x, int y) { return (IntPtr)((y << 16) | (x & 0xFFFF)); }
  public static void Click(IntPtr v, int x, int y) {
    PostMessage(v, 0x0200, IntPtr.Zero, XY(x, y)); Thread.Sleep(80);
    PostMessage(v, 0x0201, (IntPtr)1, XY(x, y)); Thread.Sleep(90);
    PostMessage(v, 0x0202, IntPtr.Zero, XY(x, y));
  }
  // No mouse wheel: Flutter scrolls where GetCursorPos says, and that fails in this window station
  // (1459), so a wheel lands anywhere. Scrolling is done by moving the focus (Tab) instead.
  public static void Chars(IntPtr v, string s) {
    foreach (char c in s) { PostMessage(v, 0x0102, (IntPtr)c, (IntPtr)1); Thread.Sleep(15); }
  }
  // Page Up/Down, End, Home, the arrows, Insert and Delete are extended keys: without bit 24 they
  // read as the number pad's keys.
  static IntPtr KeyL(uint vk, bool up) {
    uint sc = MapVirtualKey(vk, 0); long l = 1 | (sc << 16);
    if ((vk >= 0x21 && vk <= 0x28) || vk == 0x2D || vk == 0x2E) l |= 1L << 24;
    if (up) l |= 0xC0000000L;
    return (IntPtr)l;
  }
  /// A plain key press; Enter, Tab, Space and Backspace also get their WM_CHAR, as from a keyboard.
  public static void Key(IntPtr v, uint vk) {
    PostMessage(v, 0x0100, (IntPtr)vk, KeyL(vk, false));
    if (vk == 0x0D || vk == 0x09 || vk == 0x20 || vk == 0x08) PostMessage(v, 0x0102, (IntPtr)(vk == 0x0D ? 13 : (int)vk), KeyL(vk, false));
    Thread.Sleep(60);
    PostMessage(v, 0x0101, (IntPtr)vk, KeyL(vk, true));
  }
}

/// Loopback stand-ins (standin.py's job on Linux). Each connection on its own thread.
public static class Standin {
  static readonly HttpClient http = new HttpClient { Timeout = TimeSpan.FromSeconds(60) };
  static readonly HashSet<string> hop = new HashSet<string>(StringComparer.OrdinalIgnoreCase) {
    "connection", "keep-alive", "transfer-encoding", "host", "content-length", "accept-encoding", "content-type", "proxy-connection" };
  public static string LogFile;
  public static long Requests;
  static void Log(string s) { try { lock (hop) File.AppendAllText(LogFile, DateTime.Now.ToString("HH:mm:ss ") + s + "\n"); } catch { } }
  static TcpListener Listen() { var l = new TcpListener(IPAddress.Loopback, 0); l.Start(); return l; }
  static void Serve(TcpListener l, Action<TcpClient> each) {
    var t = new Thread(() => { while (true) { TcpClient c; try { c = l.AcceptTcpClient(); } catch { return; }
      var w = new Thread(() => { try { each(c); } catch (Exception e) { Log("conn: " + e.Message); } finally { try { c.Close(); } catch { } } }) { IsBackground = true }; w.Start(); } }) { IsBackground = true };
    t.Start();
  }
  static string Line(Stream s) {
    var b = new List<byte>(); int ch;
    while ((ch = s.ReadByte()) >= 0) { if (ch == '\n') break; if (ch != '\r') b.Add((byte)ch); }
    return ch < 0 && b.Count == 0 ? null : Encoding.ASCII.GetString(b.ToArray());
  }
  /// http://127.0.0.1:<port> -> upstream (https://host[:port]); answers one request per connection.
  public static int Node(string upstream) {
    var l = Listen(); upstream = upstream.TrimEnd('/');
    Serve(l, c => {
      var s = c.GetStream();
      var first = Line(s); if (string.IsNullOrEmpty(first)) return;
      var parts = first.Split(' ');
      var heads = new List<KeyValuePair<string, string>>(); int len = 0; string ctype = null; string h;
      while (!string.IsNullOrEmpty(h = Line(s))) {
        int i = h.IndexOf(':'); if (i <= 0) continue;
        string k = h.Substring(0, i).Trim(), v = h.Substring(i + 1).Trim();
        if (k.Equals("content-length", StringComparison.OrdinalIgnoreCase)) int.TryParse(v, out len);
        if (k.Equals("content-type", StringComparison.OrdinalIgnoreCase)) ctype = v;
        heads.Add(new KeyValuePair<string, string>(k, v));
      }
      var body = new byte[len]; int got = 0; while (got < len) { int n = s.Read(body, got, len - got); if (n <= 0) break; got += n; }
      var req = new HttpRequestMessage(new HttpMethod(parts[0]), upstream + parts[1]);
      if (len > 0) { req.Content = new ByteArrayContent(body); if (ctype != null) req.Content.Headers.TryAddWithoutValidation("Content-Type", ctype); }
      foreach (var kv in heads) if (!hop.Contains(kv.Key)) req.Headers.TryAddWithoutValidation(kv.Key, kv.Value);
      int code; string reason; byte[] data; var outh = new List<string>();
      try {
        var r = http.SendAsync(req).GetAwaiter().GetResult();
        code = (int)r.StatusCode; reason = r.ReasonPhrase ?? "";
        data = r.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult();
        foreach (var kv in r.Headers) if (!hop.Contains(kv.Key)) outh.Add(kv.Key + ": " + string.Join(", ", kv.Value));
        foreach (var kv in r.Content.Headers) if (kv.Key.Equals("content-type", StringComparison.OrdinalIgnoreCase)) outh.Add(kv.Key + ": " + string.Join(", ", kv.Value));
      } catch (Exception e) { code = 502; reason = "Bad Gateway"; data = Encoding.UTF8.GetBytes(e.Message); }
      Interlocked.Increment(ref Requests);
      Log("node " + parts[0] + " " + parts[1] + " -> " + code);
      var sb = new StringBuilder("HTTP/1.1 " + code + " " + reason + "\r\n");
      foreach (var x in outh) sb.Append(x + "\r\n");
      sb.Append("Content-Length: " + data.Length + "\r\nConnection: close\r\n\r\n");
      var hb = Encoding.ASCII.GetBytes(sb.ToString());
      s.Write(hb, 0, hb.Length); s.Write(data, 0, data.Length); s.Flush();
    });
    return ((IPEndPoint)l.LocalEndpoint).Port;
  }
  /// 127.0.0.1:<port> piped into TLS to host:443 (the app speaks ws:// to a loopback relay).
  public static int Relay(string host) {
    var l = Listen();
    Serve(l, c => {
      var up = new TcpClient(host, 443);
      var tls = new SslStream(up.GetStream()); tls.AuthenticateAsClient(host);
      Log("relay connection");
      var a = c.GetStream();
      var t = new Thread(() => { try { tls.CopyTo(a); } catch { } try { c.Close(); } catch { } }) { IsBackground = true }; t.Start();
      try { a.CopyTo(tls); } catch { }
      try { up.Close(); } catch { }
      t.Join(2000);
    });
    return ((IPEndPoint)l.LocalEndpoint).Port;
  }
}
'@

# UI Automation (see UIA below): the Flutter engine builds its accessibility tree when its window gets WM_GETOBJECT.
# -ReferencedAssemblies replaces Add-Type's defaults, so the runtime facades are named too.
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes, WindowsBase
$uiaRefs = @([Windows.Automation.AutomationElement].Assembly.Location, [Windows.Automation.ControlType].Assembly.Location,
  [System.Windows.Rect].Assembly.Location, 'System.Runtime', 'System.Collections', 'System.Threading', 'System.Threading.Thread', 'netstandard')
Add-Type -ReferencedAssemblies $uiaRefs -TypeDefinition (@'
using System; using System.Collections.Generic; using System.Runtime.InteropServices; using System.Threading; using System.Windows.Automation;
/// UI Automation client for the app's FLUTTERVIEW (the Flutter engine builds its accessibility tree when it
/// receives WM_GETOBJECT). Every call runs on its own STA thread (COM is initialised by the thread), and the
/// elements of the last read are kept by runtime id so a press or a value can name the node it read.
public static class UIA {
  static readonly Dictionary<string, AutomationElement> Seen = new Dictionary<string, AutomationElement>();
  static T Sta<T>(Func<T> f, int ms) {
    T r = default(T); Exception err = null;
    var t = new Thread(() => { try { r = f(); } catch (Exception e) { err = e; } });
    t.SetApartmentState(ApartmentState.STA); t.IsBackground = true; t.Start();
    if (!t.Join(ms)) throw new TimeoutException("a UIA call did not finish in " + ms + " ms");
    if (err != null) throw new Exception(err.GetType().Name + " 0x" + err.HResult.ToString("X8") + ": " + err.Message);
    return r;
  }
  static string Rid(AutomationElement e) { return string.Join(".", e.GetRuntimeId()); }
  static string Role(AutomationElement e) { return e.Cached.ControlType.ProgrammaticName.Replace("ControlType.", ""); }

  /// The nodes below [hwnd], document order: rid, ct (control type), name, aid, cls, en, off, focus, pw, tog, val,
  /// pat (supported patterns), rect.
  public static List<Dictionary<string, object>> Tree(IntPtr hwnd, int max, int ms) {
    return Sta(() => {
      var o = new List<Dictionary<string, object>>();
      var cr = new CacheRequest { TreeScope = TreeScope.Element };
      foreach (var p in new AutomationProperty[] { AutomationElement.NameProperty, AutomationElement.AutomationIdProperty,
        AutomationElement.ControlTypeProperty, AutomationElement.ClassNameProperty, AutomationElement.IsEnabledProperty,
        AutomationElement.IsOffscreenProperty, AutomationElement.HasKeyboardFocusProperty, AutomationElement.BoundingRectangleProperty,
        AutomationElement.IsPasswordProperty, AutomationElement.IsInvokePatternAvailableProperty, AutomationElement.IsValuePatternAvailableProperty,
        AutomationElement.IsTogglePatternAvailableProperty, AutomationElement.IsSelectionItemPatternAvailableProperty,
        AutomationElement.IsExpandCollapsePatternAvailableProperty, AutomationElement.IsScrollPatternAvailableProperty,
        AutomationElement.IsScrollItemPatternAvailableProperty,
        AutomationElement.IsRangeValuePatternAvailableProperty,
        TogglePatternIdentifiers.ToggleStateProperty, ValuePatternIdentifiers.ValueProperty,
        SelectionItemPatternIdentifiers.IsSelectedProperty }) cr.Add(p);
      cr.Add(TogglePattern.Pattern); cr.Add(ValuePattern.Pattern); cr.Add(SelectionItemPattern.Pattern);
      AutomationElementCollection all;
      using (cr.Activate()) {
        var root = AutomationElement.FromHandle(hwnd);
        all = root.FindAll(TreeScope.Descendants, Condition.TrueCondition);
        lock (Seen) {
          Seen.Clear();
          for (int i = 0; i < all.Count && i < max; i++) {
            var e = all[i];
            var d = new Dictionary<string, object>();
            string rid = Rid(e); Seen[rid] = e;
            d["rid"] = rid; d["ct"] = Role(e); d["name"] = e.Cached.Name; d["aid"] = e.Cached.AutomationId; d["cls"] = e.Cached.ClassName;
            d["en"] = e.Cached.IsEnabled; d["off"] = e.Cached.IsOffscreen; d["focus"] = e.Cached.HasKeyboardFocus;
            bool pw = false; try { pw = e.Cached.IsPassword; } catch { } d["pw"] = pw;
            var pat = new List<object>();
            Func<AutomationProperty, bool> av = p => { try { return (bool)e.GetCachedPropertyValue(p); } catch { return false; } };
            if (av(AutomationElement.IsInvokePatternAvailableProperty)) pat.Add("invoke");
            if (av(AutomationElement.IsValuePatternAvailableProperty)) pat.Add("value");
            if (av(AutomationElement.IsTogglePatternAvailableProperty)) pat.Add("toggle");
            if (av(AutomationElement.IsSelectionItemPatternAvailableProperty)) pat.Add("select");
            if (av(AutomationElement.IsExpandCollapsePatternAvailableProperty)) pat.Add("expand");
            if (av(AutomationElement.IsScrollPatternAvailableProperty)) pat.Add("scroll");
            if (av(AutomationElement.IsScrollItemPatternAvailableProperty)) pat.Add("scrollitem");
            if (av(AutomationElement.IsRangeValuePatternAvailableProperty)) pat.Add("range");
            d["pat"] = pat;
            if (pat.Contains((object)"toggle")) { try { d["tog"] = ((TogglePattern)e.GetCachedPattern(TogglePattern.Pattern)).Cached.ToggleState.ToString(); } catch { } }
            if (pat.Contains((object)"select")) { try { d["sel"] = ((SelectionItemPattern)e.GetCachedPattern(SelectionItemPattern.Pattern)).Cached.IsSelected; } catch { } }
            if (pat.Contains((object)"value") && !pw) { try { d["val"] = ((ValuePattern)e.GetCachedPattern(ValuePattern.Pattern)).Cached.Value; } catch { } }
            var r = e.Cached.BoundingRectangle;
            d["rect"] = r.IsEmpty ? new int[0] : new[] { (int)r.X, (int)r.Y, (int)r.Width, (int)r.Height };
            o.Add(d);
          }
        }
      }
      return o;
    }, ms);
  }

  static AutomationElement Get(string rid) {
    lock (Seen) { AutomationElement e; if (!Seen.TryGetValue(rid, out e)) throw new Exception("no node " + rid + " in the last read"); return e; }
  }
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
  [DllImport("user32.dll")] static extern bool IsWindowEnabled(IntPtr h);
  [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] static extern IntPtr GetFocus();
  [DllImport("user32.dll")] static extern int GetWindowLong(IntPtr h, int i);
  public static string Diag(IntPtr view, IntPtr top) {
    return "view visible=" + IsWindowVisible(view) + " enabled=" + IsWindowEnabled(view) + "; top visible=" + IsWindowVisible(top) + " enabled=" + IsWindowEnabled(top)
      + " style=0x" + GetWindowLong(top, -16).ToString("X8") + "; foreground=" + GetForegroundWindow().ToInt64() + " (top " + top.ToInt64() + "); GetFocus=" + GetFocus().ToInt64();
  }
  public static string Invoke(string rid, int ms) { return Sta(() => { ((InvokePattern)Get(rid).GetCurrentPattern(InvokePattern.Pattern)).Invoke(); return "ok"; }, ms); }
  public static string Toggle(string rid, int ms) { return Sta(() => { var p = (TogglePattern)Get(rid).GetCurrentPattern(TogglePattern.Pattern); p.Toggle(); return p.Current.ToggleState.ToString(); }, ms); }
  public static string Select(string rid, int ms) { return Sta(() => { ((SelectionItemPattern)Get(rid).GetCurrentPattern(SelectionItemPattern.Pattern)).Select(); return "ok"; }, ms); }
  public static string SetValue(string rid, string text, int ms) { return Sta(() => { ((ValuePattern)Get(rid).GetCurrentPattern(ValuePattern.Pattern)).SetValue(text); return "ok"; }, ms); }
  public static string Focus(string rid, int ms) { return Sta(() => { Get(rid).SetFocus(); return "ok"; }, ms); }
  public static string Scroll(string rid, int ms) { return Sta(() => { ((ScrollItemPattern)Get(rid).GetCurrentPattern(ScrollItemPattern.Pattern)).ScrollIntoView(); return "ok"; }, ms); }
}
'@)


# Legacy MSAA (IAccessible) view of the same tree: the engine answers WM_GETOBJECT for OBJID_CLIENT too.
Add-Type -AssemblyName Accessibility
Add-Type -IgnoreWarnings -ReferencedAssemblies @([Accessibility.IAccessible].Assembly.Location, 'System.Runtime', 'System.Collections', 'netstandard', 'System.Runtime.InteropServices') -TypeDefinition @'
using System; using System.Collections.Generic; using System.Runtime.InteropServices; using Accessibility;
public static class MSAA {
  [DllImport("oleacc.dll")] static extern int AccessibleObjectFromWindow(IntPtr h, uint id, ref Guid iid, [MarshalAs(UnmanagedType.Interface)] out IAccessible acc);
  [DllImport("oleacc.dll")] static extern int AccessibleChildren(IAccessible c, int first, int n, [Out, MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 2)] object[] kids, out int got);
  static IAccessible Root(IntPtr hwnd) {
    var iid = new Guid("618736E0-3C3D-11CF-810C-00AA00389B71"); IAccessible a;
    int hr = AccessibleObjectFromWindow(hwnd, 0xFFFFFFFC, ref iid, out a);
    if (hr != 0) throw new Exception("AccessibleObjectFromWindow 0x" + hr.ToString("X8"));
    return a;
  }
  static void Walk(IAccessible a, string path, int depth, List<Dictionary<string, object>> o, int max) {
    if (o.Count >= max) return;
    var d = new Dictionary<string, object>(); d["path"] = path;
    try { d["name"] = a.get_accName(0); } catch { }
    try { d["role"] = a.get_accRole(0); } catch { }
    try { d["state"] = a.get_accState(0); } catch { }
    try { d["act"] = a.get_accDefaultAction(0); } catch { }
    o.Add(d);
    int n = 0; try { n = a.accChildCount; } catch { }
    if (n == 0 || depth > 40) return;
    var kids = new object[n]; int got;
    if (AccessibleChildren(a, 0, n, kids, out got) != 0) return;
    for (int i = 0; i < got; i++) { var ia = kids[i] as IAccessible; if (ia != null) Walk(ia, path + "." + i, depth + 1, o, max); }
  }
  public static List<Dictionary<string, object>> Tree(IntPtr hwnd, int max) { var o = new List<Dictionary<string, object>>(); Walk(Root(hwnd), "0", 0, o, max); return o; }
  public static string Do(IntPtr hwnd, string path) {
    IAccessible a = Root(hwnd);
    var parts = path.Split('.');
    for (int k = 1; k < parts.Length; k++) {
      var p = parts[k];
      var kids = new object[a.accChildCount]; int got; AccessibleChildren(a, 0, kids.Length, kids, out got);
      a = (IAccessible)kids[int.Parse(p)];
    }
    a.accDoDefaultAction(0); return "done";
  }
}
'@

[Standin]::LogFile = Join-Path $Run 'standins.log'

# The app's exe: btwallet.exe from 26.10.25, epic_wallet.exe before (an update test runs both).
function AppProcs { @(Get-Process btwallet, epic_wallet -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$Run\*" }) }
function Top {
  $ps = AppProcs
  if (-not $ps) { return $null }
  foreach ($w in [TR]::Windows([int[]]($ps | ForEach-Object Id))) {
    $f = $w.Split('|')
    if ($f[2] -eq 'FLUTTER_RUNNER_WIN32_WINDOW') { return [IntPtr][long]$f[0] }
  }
  $null
}
function View { $t = Top; if (-not $t) { return $null }; $v = [TR]::Child($t, 'FLUTTERVIEW'); if ($v -eq [IntPtr]::Zero) { $null } else { $v } }
function NeedView { $v = View; if (-not $v) { throw 'no app window' }; $v }
function Mine([string]$p) { $full = [IO.Path]::GetFullPath($p); if (-not $full.StartsWith("$Run\", [StringComparison]::OrdinalIgnoreCase)) { throw "$p is not under the run folder" }; $full }
function StopMine {
  Get-Process btwallet, epic_wallet, epic, tor, unins000 -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$Run\*" } |
    ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue; "$($_.Name) $($_.Id)" }
}
function Entry { $k = Get-ItemProperty -Path $uk -ErrorAction SilentlyContinue; if ($k) { @{ version = $k.DisplayVersion; location = $k.InstallLocation; uninstall = $k.UninstallString; name = $k.DisplayName; exe = $k.DisplayIcon } } else { $null } }

# The desk store (DPAPI, entropy epic-cash-desktop/secret-store/v1, in the data folder): only keys
# that hold settings, never the wallet's secrets (seed, vault, password, keys).
$secretKeys = '(?i)seed|phrase|mnemonic|password|passphrase|secret|private|token|vault|key$|keys|recovery|pin|^lepic:'
function StoreKeys([string]$file) {
  Add-Type -AssemblyName System.Security
  $bytes = [IO.File]::ReadAllBytes((Mine $file))
  $plain = [Security.Cryptography.ProtectedData]::Unprotect($bytes, [Text.Encoding]::UTF8.GetBytes('epic-cash-desktop/secret-store/v1'), 'CurrentUser')
  $all = [Text.Encoding]::UTF8.GetString($plain) | ConvertFrom-Json -AsHashtable
  $out = [ordered]@{}
  foreach ($k in ($all.Keys | Sort-Object)) {
    if ($k -match $secretKeys) { continue }
    $out[$k] = $all[$k]
  }
  $out
}

# A settings key of the desk store, set while the app is closed; every other key is written back as
# it was read (the wallet's secrets never leave this process). Refuses the secret keys.
function StoreSet([string]$file, $set) {
  Add-Type -AssemblyName System.Security
  $f = Mine $file
  $entropy = [Text.Encoding]::UTF8.GetBytes('epic-cash-desktop/secret-store/v1')
  $plain = [Security.Cryptography.ProtectedData]::Unprotect([IO.File]::ReadAllBytes($f), $entropy, 'CurrentUser')
  $all = [Text.Encoding]::UTF8.GetString($plain) | ConvertFrom-Json -AsHashtable
  foreach ($p in $set.PSObject.Properties) {
    if ($p.Name -match $secretKeys) { throw "refusing to set the secret key $($p.Name)" }
    if (-not $all.ContainsKey($p.Name)) { throw "the store has no $($p.Name)" }
    $all[$p.Name] = [string]$p.Value
  }
  $bytes = [Text.Encoding]::UTF8.GetBytes(($all | ConvertTo-Json -Compress -Depth 4))
  $tmp = "$f.seed"
  [IO.File]::WriteAllBytes($tmp, [Security.Cryptography.ProtectedData]::Protect($bytes, $entropy, 'CurrentUser'))
  Move-Item -LiteralPath $tmp -Destination $f -Force
  @($set.PSObject.Properties | ForEach-Object Name)
}

function Do-Cmd($c) {
  switch ($c.op) {
    'ping' { return @{ ok = $true; user = $env:USERNAME; profile = $env:USERPROFILE; entry = (Entry) } }
    'entry' { return @{ ok = $true; entry = (Entry) } }
    'standins' {
      $n = [Standin]::Node([string]$c.node)
      $r = [Standin]::Relay([string]$c.relay)
      Rep "stand-ins: node 127.0.0.1:$n -> $($c.node), relay 127.0.0.1:$r -> $($c.relay)"
      return @{ ok = $true; node = $n; relay = $r }
    }
    'setup' {
      # Setup with the given arguments; its USERPROFILE is the run's home (a per-user install goes there)
      $exe = Mine $c.exe
      $p = Start-Process -FilePath $exe -ArgumentList @($c.args) -PassThru
      if ($c.wait -eq $false) { $started[$p.Id] = $p; return @{ ok = $true; pid = $p.Id } }
      $done = $p.WaitForExit([int]($c.wait_s ?? 300) * 1000)
      if (-not $done) { Stop-Process -Id $p.Id -Force; return @{ ok = $false; error = 'setup timed out' } }
      return @{ ok = ($p.ExitCode -eq 0); exit = $p.ExitCode; entry = (Entry) }
    }
    'wait_exit' {
      # Setup started here keeps its process object, so its exit code is known
      $p = $started[[int]$c.pid] ?? (Get-Process -Id $c.pid -ErrorAction SilentlyContinue)
      if (-not $p) { return @{ ok = $true; exited = $true } }
      $done = $p.WaitForExit([int]$c.wait_s * 1000)
      return @{ ok = $true; exited = $done; exit = $(if ($done) { $p.ExitCode }) }
    }
    'start' {
      $exe = Mine $c.exe
      $p = Start-Process -FilePath $exe -WorkingDirectory (Split-Path $exe) -PassThru
      return @{ ok = $true; pid = $p.Id }
    }
    'window' {
      # waits up to wait_s for the app's window; its client size
      $end = (Get-Date).AddSeconds([int]($c.wait_s ?? 0))
      do { $v = View; if ($v) { break }; Start-Sleep -Milliseconds 400 } while ((Get-Date) -lt $end)
      $ps = AppProcs
      $wins = if ($ps) { [TR]::Windows([int[]]($ps | ForEach-Object Id)) } else { @() }
      $procs = @($ps | ForEach-Object { "$($_.Id) $($_.Path) $($_.FileVersion)" })
      if (-not $v) { return @{ ok = $false; procs = $procs; windows = @($wins) } }
      $sz = [TR]::Client($v)
      return @{ ok = $true; w = $sz[0]; h = $sz[1]; procs = $procs; windows = @($wins) }
    }
    'procs' { return @{ ok = $true; procs = @(Get-Process btwallet, epic_wallet, epic, tor, unins000 -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$Run\*" } | ForEach-Object { "$($_.Name) $($_.Id) $($_.Path)" }) } }
    'uia_tree' {
      # the accessibility tree of the app's view, waiting up to wait_s for the engine to build it (it turns
      # semantics on when the first client asks); nodes carry a rid that the other uia_ ops take
      $v = NeedView
      $end = (Get-Date).AddSeconds([int]($c.wait_s ?? 0))
      do {
        $nodes = [UIA]::Tree($v, [int]($c.max ?? 1500), 30000)
        if ($nodes.Count -ge [int]($c.min ?? 1)) { break }
        Start-Sleep -Milliseconds 500
      } while ((Get-Date) -lt $end)
      return @{ ok = $true; n = $nodes.Count; nodes = @($nodes) }
    }
    'uia_diag' {
      # what the window looks like to Win32 (visible, enabled, foreground) and the legacy MSAA root
      $v = NeedView; $t = Top
      return @{ ok = $true; view = $v.ToInt64(); top = $t.ToInt64(); info = [UIA]::Diag($v, $t) }
    }
    'uia_show' {
      # the runner creates its window hidden and shows it after the first frame; on this station nothing sees it
      $t = Top; if (-not $t) { return @{ ok = $false; error = 'no app window' } }
      return @{ ok = $true; was_visible = [UIA]::ShowWindow($t, [int]($c.cmd ?? 8)) }
    }
    'msaa_tree' { $v = NeedView; return @{ ok = $true; nodes = @([MSAA]::Tree($v, [int]($c.max ?? 800))) } }
    'msaa_do' { $v = NeedView; return @{ ok = $true; r = [MSAA]::Do($v, [string]$c.path) } }
    'uia_invoke' { return @{ ok = $true; r = [UIA]::Invoke([string]$c.rid, 15000) } }
    'uia_toggle' { return @{ ok = $true; r = [UIA]::Toggle([string]$c.rid, 15000) } }
    'uia_select' { return @{ ok = $true; r = [UIA]::Select([string]$c.rid, 15000) } }
    'uia_focus' { return @{ ok = $true; r = [UIA]::Focus([string]$c.rid, 15000) } }
    'uia_scroll_to' { return @{ ok = $true; r = [UIA]::Scroll([string]$c.rid, 15000) } }
    'uia_set_value' {
      # text from a file under the run folder (a secret) or inline; never logged
      $t = if ($c.file) { (Get-Content -Raw -LiteralPath (Mine $c.file)).TrimEnd("`r", "`n") } else { [string]$c.text }
      return @{ ok = $true; r = [UIA]::SetValue([string]$c.rid, $t, 15000) }
    }
    'click' { $v = NeedView; [TR]::Click($v, [int]$c.x, [int]$c.y); return @{ ok = $true } }
    'type' {
      $v = NeedView
      $t = if ($c.file) { (Get-Content -Raw -LiteralPath (Mine $c.file)).TrimEnd("`r", "`n") } else { [string]$c.text }
      [TR]::Chars($v, $t)
      return @{ ok = $true; n = $t.Length }
    }
    'keys' {
      # plain keys by virtual-key code, with a pause after each
      $v = NeedView
      foreach ($k in @($c.vks)) { [TR]::Key($v, [uint32]$k); Start-Sleep -Milliseconds ([int]($c.gap_ms ?? 400)) }
      return @{ ok = $true }
    }
    'clipboard' { return @{ ok = $true; text = [string](Get-Clipboard -Raw) } }
    'clear_clipboard' { Set-Clipboard -Value ' '; return @{ ok = $true } }
    'close' {
      $t = Top
      if (-not $t) { return @{ ok = $false; error = 'no app window' } }
      [void][TR]::PostMessage($t, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero)
      $end = (Get-Date).AddSeconds([int]($c.wait_s ?? 60))
      while ((AppProcs).Count -gt 0 -and (Get-Date) -lt $end) { Start-Sleep -Milliseconds 300 }
      return @{ ok = ((AppProcs).Count -eq 0) }
    }
    'stop_all' { return @{ ok = $true; stopped = @(StopMine) } }
    'store' { return @{ ok = $true; keys = (StoreKeys $c.file) } }
    'store_set' { return @{ ok = $true; set = @(StoreSet $c.file $c.set) } }
    'put_db' {
      # a wallet database seeded on the build machine (uploaded to the run folder) into place, the app closed;
      # its -wal was folded in, so the old -wal and -shm go
      if (AppProcs) { return @{ ok = $false; error = 'the app is running' } }
      $to = Mine $c.to
      Copy-Item -LiteralPath (Mine $c.from) -Destination $to -Force
      foreach ($x in '-wal', '-shm') { if (Test-Path -LiteralPath "$to$x") { Remove-Item -LiteralPath "$to$x" -Force } }
      return @{ ok = $true }
    }
    'write_file' {
      # a small text file under the run folder (the update-target mark)
      $f = Mine $c.file
      New-Item -ItemType Directory -Force (Split-Path $f) | Out-Null
      Set-Content -LiteralPath $f -Value ([string]$c.text) -NoNewline -Encoding utf8
      return @{ ok = $true }
    }
    'uninstall' {
      $e = Entry
      if (-not $e) { return @{ ok = $true; note = 'nothing installed' } }
      if (-not ([string]$e.location).StartsWith("$Run\", [StringComparison]::OrdinalIgnoreCase)) { return @{ ok = $false; error = "installed at $($e.location), not this run's: left alone" } }
      $u = ([string]$e.uninstall) -replace '"', ''
      $p = Start-Process $u -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART' -Wait -PassThru
      Start-Sleep 3
      return @{ ok = ($p.ExitCode -eq 0); exit = $p.ExitCode; entry = (Entry) }
    }
    'ps' {
      # a PowerShell snippet in this job (diagnostics); its output as text
      $out = & ([scriptblock]::Create([string]$c.code)) 2>&1 | Out-String -Width 300
      return @{ ok = $true; out = $out }
    }
    default { return @{ ok = $false; error = "unknown op $($c.op)" } }
  }
}

$started = @{}
$last = Get-Date
$quit = $false
try {
  while (-not $quit) {
    if (Test-Path (Join-Path $Run 'stop')) { Rep 'stop file'; break }
    $f = Get-ChildItem -LiteralPath $cmdDir -Filter '*.json' -File -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -First 1
    if (-not $f) {
      if (((Get-Date) - $last).TotalMinutes -gt $IdleMin) { Rep "idle $IdleMin min: quitting"; break }
      Start-Sleep -Milliseconds 150
      continue
    }
    $last = Get-Date
    $res = $null
    try {
      $c = Get-Content -Raw -LiteralPath $f.FullName | ConvertFrom-Json
      if ($c.op -eq 'quit') { $quit = $true; $res = @{ ok = $true } }
      else { $res = Do-Cmd $c }
    } catch {
      $res = @{ ok = $false; error = "$($_.Exception.Message)" }
    }
    Rep "$($f.BaseName) $($c.op) -> ok=$($res.ok)$(if ($res.error) { ' ' + $res.error })"
    $tmp = Join-Path $resDir "$($f.BaseName).tmp"
    $res | ConvertTo-Json -Depth 8 -Compress | Set-Content -LiteralPath $tmp -Encoding utf8
    Move-Item -LiteralPath $tmp -Destination (Join-Path $resDir "$($f.BaseName).json") -Force
    Remove-Item -LiteralPath $f.FullName -Force
  }
} finally {
  $s = @(StopMine)
  Rep "agent end; stopped: $($s -join ', ')"
}
