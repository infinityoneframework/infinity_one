# unbrella.conf
use Mix.Config
config :unbrella, plugins: [mscs: [module: Mscs, application: Mscs.Application,
  base_mac_address: 87241261056, cs_ip: "192.168.1.150", ucxport: 7000],
 ucc_admin: [module: UccAdmin, application: UccAdmin.Application],
 ucc_chat: [module: UccChat, application: UccChat.Application,
  schemas: [UccChat.Accounts.Account, UccChat.Accounts.User],
  router: UccChatWeb.Router, page_size: 150, defer: true,
  emoji_one: [ascii: true, wrapper: :span, id_class: "emojione-"]],
 ucc_dialer: [module: UcxDialer, enabled: true,
  dial_translation: "1, NXXNXXXXXX"], ucc_settings: [module: UccSettings],
 ucc_ui_flex_tab: [module: UccUiFlexTab], ucc_webrtc: [module: UccWebrtc],
 ucx_adapter: [module: UcxAdapter, application: UcxAdapter.Application],
 ucx_presence: [module: UcxPresence, application: UcxPresence.Application,
  schemas: [UcxPresence.Accounts.User, UcxPresence.Accounts.PhoneNumber],
  enabled: true]]
