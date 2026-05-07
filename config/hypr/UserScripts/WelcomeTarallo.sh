#!/usr/bin/env bash
# Welcome screen Hyprland Tarallo

CONFIG_FILE="$HOME/.config/tarallo-welcome"
AUTOSTART=false
[[ "$1" == "--autostart" ]] && AUTOSTART=true

[[ ! -f "$CONFIG_FILE" ]] && echo "SHOW_ON_STARTUP=true" > "$CONFIG_FILE"
source "$CONFIG_FILE"

[[ "$AUTOSTART" == true && "$SHOW_ON_STARTUP" != "true" ]] && exit 0

WALLPAPER=$(readlink -f ~/.config/rofi/.current_wallpaper 2>/dev/null)

python3 - "$CONFIG_FILE" "$WALLPAPER" <<'PYEOF'
import sys, os, subprocess
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GdkPixbuf, Pango

CONFIG_FILE = sys.argv[1]
WALLPAPER   = sys.argv[2] if len(sys.argv) > 2 else ""

def read_show_on_startup():
    try:
        for line in open(CONFIG_FILE):
            if line.startswith("SHOW_ON_STARTUP="):
                return line.strip().split("=")[1] == "true"
    except:
        pass
    return True

def write_show_on_startup(val):
    with open(CONFIG_FILE, "w") as f:
        f.write(f"SHOW_ON_STARTUP={'true' if val else 'false'}\n")

def run(cmd):
    subprocess.Popen(cmd, shell=True)

CSS = b"""
* {
    background-color: transparent;
}
window {
    background-color: transparent;
    color: #ffffff;
}
#header {
    background-color: transparent;
    padding: 24px;
}
#title {
    font-size: 22px;
    font-weight: bold;
    color: #ffffff;
    text-shadow: 1px 1px 4px rgba(0,0,0,0.9);
}
#subtitle {
    font-size: 13px;
    color: #ccddee;
    margin-top: 4px;
    text-shadow: 1px 1px 3px rgba(0,0,0,0.9);
}
.action-btn {
    background-color: transparent;
    color: #ffffff;
    border: 1px solid rgba(255, 255, 255, 0.25);
    border-radius: 8px;
    padding: 12px 16px;
    font-size: 13px;
    margin: 4px 16px;
}
.action-btn:hover {
    background-color: rgba(30, 142, 255, 0.75);
    color: #ffffff;
    border-color: #1E8EFF;
}
.action-btn label {
    font-size: 13px;
    text-shadow: 1px 1px 3px rgba(0,0,0,0.8);
}
#footer {
    background-color: transparent;
    padding: 12px 20px;
}
#close-btn {
    background-color: rgba(30, 142, 255, 0.85);
    color: #ffffff;
    border: none;
    border-radius: 6px;
    padding: 8px 24px;
    font-weight: bold;
    font-size: 13px;
}
#close-btn:hover {
    background-color: #1E8EFF;
}
checkbutton {
    color: #ccddee;
    font-size: 13px;
    text-shadow: 1px 1px 3px rgba(0,0,0,0.9);
}
checkbutton check {
    background-color: rgba(0,0,0,0.4);
    border-color: #1E8EFF;
}
checkbutton check:checked {
    background-color: #1E8EFF;
}
"""

ACTIONS = [
    ("📋", "Cosa ho installato",             "Scopri le funzionalità incluse nel fork",
     None),
    ("⌨️", "Tasti rapidi",                    "Visualizza tutte le scorciatoie da tastiera",
     "$HOME/.config/hypr/scripts/KeyBinds.sh"),
    ("🌤️", "Configura meteo",                 "Imposta la tua città per il widget meteo",
     "$HOME/.config/hypr/UserScripts/WeatherCity.sh"),
    ("🎮", "Game Launcher",                   "Apri il launcher dei giochi",
     "gamelauncher.sh"),
    ("🔊", "Messaggio di benvenuto vocale",   "Personalizza il saluto all'avvio",
     "$HOME/.config/hypr/UserScripts/BenvenutoConfig.sh"),
    ("🖐️", "Configurazione biometrica",        "Imposta fingerprint e riconoscimento facciale",
     "$HOME/.config/hypr/UserScripts/BiometricsSetup.sh"),
    ("📦", "Installa pacchetti opzionali",    "Browser, gaming, chat vocale — aggiungibili in qualsiasi momento",
     "$HOME/.config/hypr/UserScripts/PostInstall.sh"),
    ("🐛", "Segnala un problema",             "Apri la pagina GitHub Issues",
     "xdg-open https://github.com/kilian85/Hyprland-Dots-Tarallo/issues"),
]

FEATURES = [
    "🇮🇹  Interfaccia completamente in italiano",
    "🎮  Game Launcher con griglia e cover automatiche",
    "🔋  Notifiche batteria intelligenti (multi-batteria)",
    "🌤️  Meteo in waybar e lockscreen (Open-Meteo, no API key)",
    "👋  Saluto vocale personalizzabile al login",
    "🖐️  Fingerprint + riconoscimento facciale (Howdy)",
    "🖥️  Selettore temi SDDM con miniature",
    "🔐  Wizard biometrico guidato al primo avvio",
    "📸  Snapshot automatici prima di ogni aggiornamento",
    "🔆  SwayOSD per volume, luminosità e Caps Lock",
    "💻  Ottimizzazioni batteria e ventole ThinkPad",
    "🌐  Menu scelta browser e pacchetti gaming",
    "🎨  Tema GRUB kawaii preinstallato",
]

class WelcomeWindow(Gtk.Window):
    def __init__(self):
        super().__init__(title="Hyprland Tarallo")
        self.set_default_size(540, 620)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_resizable(False)

        # CSS
        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        # Sfondo wallpaper: cover (scala per coprire tutta la finestra, ritaglia al centro)
        self._wp_tmp = None
        if WALLPAPER and os.path.exists(WALLPAPER):
            try:
                import tempfile
                pb = GdkPixbuf.Pixbuf.new_from_file(WALLPAPER)
                win_w, win_h = 540, 620
                scale = max(win_w / pb.get_width(), win_h / pb.get_height())
                new_w = int(pb.get_width() * scale)
                new_h = int(pb.get_height() * scale)
                pb_scaled = pb.scale_simple(new_w, new_h, GdkPixbuf.InterpType.BILINEAR)
                off_x = (new_w - win_w) // 2
                off_y = (new_h - win_h) // 2
                pb_crop = pb_scaled.new_subpixbuf(off_x, off_y, win_w, win_h)
                tmp = tempfile.NamedTemporaryFile(suffix=".png", delete=False)
                pb_crop.savev(tmp.name, "png", [], [])
                self._wp_tmp = tmp.name
                wp_css = f'window {{ background-image: url("{tmp.name}"); background-repeat: no-repeat; }}'.encode()
                wp_provider = Gtk.CssProvider()
                wp_provider.load_from_data(wp_css)
                Gtk.StyleContext.add_provider_for_screen(
                    Gdk.Screen.get_default(), wp_provider,
                    Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION + 1
                )
            except Exception as e:
                pass

        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.add(main_box)

        # Header
        header = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        header.set_name("header")

        title = Gtk.Label(label="Hyprland Tarallo")
        title.set_name("title")
        header.pack_start(title, False, False, 0)

        subtitle = Gtk.Label(label="Versione personalizzata di JaKooLit Hyprland")
        subtitle.set_name("subtitle")
        subtitle.set_margin_top(4)
        header.pack_start(subtitle, False, False, 0)

        main_box.pack_start(header, False, False, 0)

        # Pulsanti azioni
        actions_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        actions_box.set_margin_top(12)
        actions_box.set_margin_bottom(8)

        for icon, label, desc, cmd in ACTIONS:
            btn = Gtk.Button()
            btn.set_relief(Gtk.ReliefStyle.NONE)
            btn.get_style_context().add_class("action-btn")

            row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
            ico = Gtk.Label(label=icon)
            ico.set_width_chars(2)

            text_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
            lbl = Gtk.Label(label=label)
            lbl.set_halign(Gtk.Align.START)
            lbl.set_markup(f"<b>{label}</b>")
            desc_lbl = Gtk.Label(label=desc)
            desc_lbl.set_halign(Gtk.Align.START)
            desc_lbl.get_style_context().add_class("desc")
            markup = f'<span size="11000" foreground="#7AA8C7">{desc}</span>'
            desc_lbl.set_markup(markup)

            text_box.pack_start(lbl, False, False, 0)
            text_box.pack_start(desc_lbl, False, False, 0)
            row.pack_start(ico, False, False, 0)
            row.pack_start(text_box, True, True, 0)
            btn.add(row)

            if cmd is None:
                btn.connect("clicked", self.show_features)
            else:
                btn.connect("clicked", lambda _, c=cmd: run(os.path.expandvars(c)))

            actions_box.pack_start(btn, False, False, 0)

        main_box.pack_start(actions_box, False, False, 0)

        # Footer
        footer = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        footer.set_name("footer")

        self.toggle = Gtk.CheckButton(label="Mostra all'avvio")
        self.toggle.set_active(read_show_on_startup())
        self.toggle.connect("toggled", self.on_toggle)
        footer.pack_start(self.toggle, True, True, 0)

        close_btn = Gtk.Button(label="Chiudi")
        close_btn.set_name("close-btn")
        close_btn.connect("clicked", Gtk.main_quit)
        footer.pack_end(close_btn, False, False, 0)

        main_box.pack_start(footer, False, False, 0)
        self.connect("destroy", Gtk.main_quit)
        self.show_all()

    def on_toggle(self, widget):
        write_show_on_startup(widget.get_active())

    def show_features(self, _):
        dialog = Gtk.Dialog(title="Funzionalità incluse", parent=self,
                            flags=Gtk.DialogFlags.MODAL)
        dialog.set_default_size(480, -1)
        dialog.add_button("Chiudi", Gtk.ResponseType.CLOSE)
        box = dialog.get_content_area()
        box.set_margin_top(16)
        box.set_margin_bottom(8)
        box.set_margin_start(20)
        box.set_margin_end(20)
        for feat in FEATURES:
            lbl = Gtk.Label(label=feat)
            lbl.set_halign(Gtk.Align.START)
            lbl.set_margin_bottom(6)
            box.pack_start(lbl, False, False, 0)
        dialog.show_all()
        dialog.run()
        dialog.destroy()

win = WelcomeWindow()
Gtk.main()
PYEOF
