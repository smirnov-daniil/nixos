{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.telegram-notify;
in {
  options.services.telegram-notify = {
    enable = mkEnableOption "Telegram notifications";
    
    enableSystemNotifications = mkOption {
      type = types.bool;
      default = true;
      description = "Включить системные уведомления";
    };
    
    enableServiceNotifications = mkOption {
      type = types.bool;
      default = true;
      description = "Включить уведомления о сервисах";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets."telegram/bot_token" = {};
    sops.secrets."telegram/chat_id" = {};

    services.telegram-notify = {
      enable = true;
      botToken = config.sops.secrets.telegram_bot_token.path;
      chatId = config.sops.secrets.telegram_chat_id.path;
      
      # Настройки по умолчанию
      settings = {
        message_template = "🚀 {service} on {host}: {status}";
        success_message = "✅ Service {service} started successfully";
        failure_message = "❌ Service {service} failed";
      };
    };

    # Системные уведомления (опционально)
    systemd.services = lib.mkIf cfg.enableSystemNotifications {
      "notify-on-reboot" = {
        description = "Notify on system reboot";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.curl}/bin/curl -s -X POST \
            https://api.telegram.org/bot$$(cat ${config.sops.secrets.telegram_bot_token.path})/sendMessage \
            -d chat_id=$$(cat ${config.sops.secrets.telegram_chat_id.path}) \
            -d text=\"🖥️ Server $(hostname) rebooted and is online\"";
        };
      };
    };
  };
}
