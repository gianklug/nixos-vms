{ config, pkgs, ... }:
{
  services.prometheus.alertmanager = {
    enable = true;
    webExternalUrl = "https://alertmanager.gk.wtf";
    configuration = {
      global = { };
      route = {
        group_by = ["instance"]; # group by instance to prevent spam
        group_wait = "30s"; # delay alerts by 30s to collect grouped events
        group_interval = "1m"; # notify about updates in the group every minute
        repeat_interval = "8h"; # repeat alerts all 8h

        routes = [
          {
            matchers = [
              "alertname=\"PrometheusAlertmanagerE2eDeadManSwitch\""
            ];
            receiver = "null";
          }
        ];

        receiver = "telegram"; # Default receiver
      };
      receivers = [
        {
          name = "telegram";
          telegram_configs = [
            {
              send_resolved = true;
              bot_token_file =
                config.age.secrets.alertmanager-telegram-token.path;
              chat_id = 187668419;
              parse_mode = "Markdown";
              message = "{{ template \"telegram.message\" . }}";
            }
          ];
        }
        {
          name = "null";
        }
      ];
      templates = [
        ./telegram.tmpl
      ];
    };
  };
}
