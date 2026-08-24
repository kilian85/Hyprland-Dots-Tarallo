-- windowrules.lua — regole di finestra predefinite (ex configs/WindowRules.conf)
-- Le regole personali vanno in lua/userwindowrules.lua, che viene caricato dopo.
--
-- L'ordine conta: a parita' di tipo vince l'ultima regola che corrisponde, e le
-- regole con `name` vengono valutate prima di quelle anonime.

local rule = hl.window_rule

--------------------------------------------------------------------
-- Etichette: raggruppano le app che devono avere lo stesso trattamento
--------------------------------------------------------------------

-- browser
rule({ match = { class = "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin)$" }, tag = "+browser" })
rule({ match = { class = "^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$" },                      tag = "+browser" })
rule({ match = { class = "^(chrome-.+-Default)$" },                                            tag = "+browser" })
rule({ match = { class = "^([Cc]hromium)$" },                                                  tag = "+browser" })
rule({ match = { class = "^([Mm]icrosoft-edge(-stable|-beta|-dev|-unstable))$" },               tag = "+browser" })
rule({ match = { class = "^(Brave-browser(-beta|-dev|-unstable)?)$" },                          tag = "+browser" })
rule({ match = { class = "^([Tt]horium-browser|[Cc]achy-browser)$" },                           tag = "+browser" })
rule({ match = { class = "^(zen-alpha|zen)$" },                                                 tag = "+browser" })

-- notifiche
rule({ match = { class = "^(swaync-control-center|swaync-notification-window|swaync-client|class)$" }, tag = "+notif" })

-- pannelli delle dotfiles
rule({ match = { title = "^(KooL Quick Cheat Sheet)$" }, tag = "+KooL_Cheat" })
rule({ match = { title = "^(KooL Hyprland Settings)$" }, tag = "+KooL_Settings" })
rule({ match = { class = "^(nwg-displays|nwg-look)$" },  tag = "+KooL-Settings" })

-- terminali
rule({ match = { class = "^(Alacritty|kitty|kitty-dropterm)$" }, tag = "+terminal" })

-- posta
rule({ match = { class = "^([Tt]hunderbird|org.mozilla.Thunderbird)$" }, tag = "+email" })
rule({ match = { class = "^(eu.betterbird.Betterbird)$" },               tag = "+email" })
rule({ match = { class = "^(org.gnome.Evolution)$" },                    tag = "+email" })

-- sviluppo
rule({ match = { class = "^(codium|codium-url-handler|VSCodium)$" }, tag = "+projects" })
rule({ match = { class = "^(VSCode|code|code-url-handler)$" },       tag = "+projects" })
rule({ match = { class = "^(jetbrains-.+)$" },                       tag = "+projects" })
rule({ match = { class = "^(dev.zed.Zed|antigravity)$" },            tag = "+projects" })

-- condivisione schermo
rule({ match = { class = "^(com.obsproject.Studio)$" }, tag = "+screenshare" })

-- messaggistica
rule({ match = { class = "^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$" },                        tag = "+im" })
rule({ match = { class = "^([Ff]erdium)$" },                                              tag = "+im" })
rule({ match = { class = "^([Ww]hatsapp-for-linux)$" },                                   tag = "+im" })
rule({ match = { class = "^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$" },     tag = "+im" })
rule({ match = { class = "^(teams-for-linux)$" },                                         tag = "+im" })
rule({ match = { class = "^(im.riot.Riot|Element)$" },                                    tag = "+im" })

-- giochi
rule({ match = { class = "^(gamescope)$" },          tag = "+games" })
rule({ match = { class = "^(steam_app_\\d+)$" },     tag = "+games" })

-- store di giochi
rule({ match = { class = "^([Ss]team)$" },                     tag = "+gamestore" })
rule({ match = { title = "^([Ll]utris)$" },                    tag = "+gamestore" })
rule({ match = { class = "^(com.heroicgameslauncher.hgl)$" },  tag = "+gamestore" })

-- gestori file
rule({ match = { class = "^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt)$" }, tag = "+file-manager" })
rule({ match = { class = "^(app.drey.Warp)$" },                              tag = "+file-manager" })

-- sfondi
rule({ match = { class = "^([Ww]aytrogen)$" }, tag = "+wallpaper" })

-- multimedia
rule({ match = { class = "^([Aa]udacious)$" }, tag = "+multimedia" })
rule({ match = { class = "^([Mm]pv|vlc)$" },   tag = "+multimedia_video" })

-- impostazioni
rule({ match = { title = "^(ROG Control)$" },                            tag = "+settings" })
rule({ match = { class = "^(wihotspot(-gui)?)$" },                       tag = "+settings" })
rule({ match = { class = "^([Bb]aobab|org.gnome.[Bb]aobab)$" },          tag = "+settings" })
rule({ match = { class = "^(gnome-disks|wihotspot(-gui)?)$" },           tag = "+settings" })
rule({ match = { title = "(Kvantum Manager)" },                          tag = "+settings" })
rule({ match = { class = "^(file-roller|org.gnome.FileRoller)$" },       tag = "+settings" })
rule({ match = { class = "^(nm-applet|nm-connection-editor|blueman-manager)$" }, tag = "+settings" })
rule({ match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" }, tag = "+settings" })
rule({ match = { class = "^(qt5ct|qt6ct)$" },                            tag = "+settings" })
rule({ match = { class = "(xdg-desktop-portal-gtk)" },                   tag = "+settings" })
rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, tag = "+settings" })
rule({ match = { class = "^([Rr]ofi)$" },                                tag = "+settings" })
rule({ match = { class = "^(btrfs-assistant)$" },                        tag = "+settings" })
rule({ match = { class = "^(timeshift-gtk)$" },                          tag = "+settings" })

-- visualizzatori
rule({ match = { class = "^(gnome-system-monitor|org.gnome.SystemMonitor|io.missioncenter.MissionCenter)$" }, tag = "+viewer" })
rule({ match = { class = "^(evince)$" },                 tag = "+viewer" })
rule({ match = { class = "^(eog|org.gnome.Loupe)$" },     tag = "+viewer" })

--------------------------------------------------------------------
-- Eccezioni per i video: niente sfocatura ne' trasparenza
--------------------------------------------------------------------

rule({ match = { tag = "multimedia_video" }, no_blur = true })
rule({ match = { tag = "multimedia_video" }, opacity = "1.0" })
rule({ match = { tag = "multimedia" },       no_blur = true })
rule({ match = { tag = "multimedia" },       opacity = "1.0" })

--------------------------------------------------------------------
-- Posizione
--------------------------------------------------------------------

rule({ match = { tag = "KooL_Cheat" },     center = true })
rule({ match = { tag = "KooL-Settings" },  center = true })
rule({ match = { title = "^(ROG Control)$" }, center = true })
rule({ match = { title = "^(Keybindings)$" }, center = true })
rule({ match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" }, center = true })
rule({ match = { class = "^([Ff]erdium)$" }, center = true })

-- Niente sospensione mentre un'app e' a schermo intero
rule({ match = { fullscreen = true }, idle_inhibit = "fullscreen" })

--------------------------------------------------------------------
-- Finestre flottanti
--------------------------------------------------------------------

rule({ match = { tag = "KooL_Cheat" },    float = true })
rule({ match = { tag = "wallpaper" },     float = true, center = true })
rule({ match = { tag = "settings" },      float = true, center = true })
rule({ match = { tag = "viewer" },        float = true, center = true })
rule({ match = { tag = "KooL-Settings" }, float = true, center = true })
rule({ match = { class = "([Zz]oom|onedriver|onedriver-launcher)" },   float = true })
rule({ match = { class = "(org.gnome.Calculator|qalculate-gtk)" },     float = true })
rule({ match = { class = "^(mpv|com.github.rafostar.Clapper)$" },      float = true })
rule({ match = { class = "^([Qq]alculate-gtk)$" },                     float = true })
rule({ match = { class = "^([Ff]erdium)$" },                           float = true })

-- Finestre di dialogo
rule({ match = { title = "^(Authentication Required)$" }, float = true, center = true })
rule({
    match = { class = "(codium|codium-url-handler|VSCodium)", title = "negative:(.*codium.*|.*VSCodium.*)" },
    float = true,
})
rule({
    match = { class = "^(com.heroicgameslauncher.hgl)$", title = "negative:(Heroic Games Launcher)" },
    float = true,
})
rule({
    match = { class = "^([Ss]team)$", title = "negative:^([Ss]team)$" },
    float = true,
})
rule({
    match = { title = "^(Add Folder to Workspace)$" },
    float = true, center = true,
    size  = { "monitor_w*0.7", "monitor_h*0.6" },
})
rule({
    match = { title = "^(Save As)$" },
    float = true, center = true,
    size  = { "monitor_w*0.7", "monitor_h*0.6" },
})
rule({
    match = { initial_title = "(Open Files)" },
    float = true,
    size  = { "monitor_w*0.7", "monitor_h*0.6" },
})
rule({
    match = { title = "^(SDDM Background)$" },
    float = true, center = true,
    size  = { "monitor_w*0.16", "monitor_h*0.12" },
})
rule({
    match = { class = "^(yad)$" },
    float = true, center = true,
    size  = { "monitor_w*0.2", "monitor_h*0.2" },
})
rule({ match = { class = "^(hyprland-donate-screen)$" }, float = true, center = true })

--------------------------------------------------------------------
-- Trasparenza (attiva / inattiva)
--------------------------------------------------------------------

rule({ match = { tag = "browser" },      opacity = "0.99 0.8" })
rule({ match = { tag = "projects" },     opacity = "0.9 0.8" })
rule({ match = { tag = "im" },           opacity = "0.94 0.86" })
rule({ match = { tag = "multimedia" },   opacity = "0.94 0.86" })
rule({ match = { tag = "file-manager" }, opacity = "0.9 0.8" })
rule({ match = { tag = "terminal" },     opacity = "0.9 0.7" })
rule({ match = { tag = "settings" },     opacity = "0.8 0.7" })
rule({ match = { tag = "viewer" },       opacity = "0.82 0.75" })
rule({ match = { tag = "wallpaper" },    opacity = "0.9 0.7" })
rule({ match = { class = "^(gedit|org.gnome.TextEditor|mousepad)$" }, opacity = "0.8 0.7" })
rule({ match = { class = "^(deluge)$" },   opacity = "0.9 0.8" })
rule({ match = { class = "^(seahorse)$" }, opacity = "0.9 0.8" })
rule({ match = { title = "^(Picture-in-Picture)$" }, opacity = "0.95 0.75" })

--------------------------------------------------------------------
-- Dimensioni
--------------------------------------------------------------------

rule({ match = { tag = "KooL_Cheat" }, size = { "monitor_w*0.65", "monitor_h*0.9" } })
rule({ match = { tag = "wallpaper" },  size = { "monitor_w*0.7",  "monitor_h*0.7" } })
rule({ match = { tag = "settings" },   size = { "monitor_w*0.7",  "monitor_h*0.7" } })
rule({ match = { class = "^([Ff]erdium)$" }, size = { "monitor_w*0.6", "monitor_h*0.7" } })

--------------------------------------------------------------------
-- Giochi: niente sfocatura, niente schermo intero forzato
--------------------------------------------------------------------

rule({ match = { tag = "games" }, no_blur = true, fullscreen = false })

-- Evita che le finestrelle di IntelliJ rubino il fuoco al passaggio del mouse
rule({ match = { class = "^(jetbrains-*)" }, no_initial_focus = true })
rule({ match = { title = "^(wind.*)$" },     no_initial_focus = true })

--------------------------------------------------------------------
-- Regole sui layer (barre, menu, sfondi)
--------------------------------------------------------------------

hl.layer_rule({ match = { namespace = "rofi" },                 blur = true })
hl.layer_rule({ match = { namespace = "notifications" },        blur = true })
hl.layer_rule({ match = { namespace = "quickshell:overview" },  blur = true, ignore_alpha = 0.5 })

--------------------------------------------------------------------
-- Regole con nome, per i casi particolari
--------------------------------------------------------------------

rule({
    name   = "Whatsapp-zapzap",
    match  = { class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" },
    size   = { "monitor_w*0.6", "monitor_h*0.7" },
    center = true,
})

rule({
    name              = "Picture-in-Picture",
    match             = { title = "^(Picture-in-Picture)$" },
    float             = true,
    move              = { "monitor_w*0.72", "monitor_h*0.07" },
    opacity           = "0.95 0.75",
    pin               = true,
    keep_aspect_ratio = true,
    size              = { "monitor_w*0.3", "monitor_h*0.3" },
})

-- Finestra di avanzamento delle copie di Thunar
rule({
    name   = "Thunar-Progress-bar",
    match  = { class = "^(thunar)$", title = "^(File Operation Progress)$" },
    float  = true,
    center = true,
    size   = { "monitor_w*0.26", "monitor_h*0.18" },
})
