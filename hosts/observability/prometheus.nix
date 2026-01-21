{ config, pkgs, ... }:
{
  services.prometheus = {
    enable = true;
    webExternalUrl = "https://prometheus.gk.wtf";
    globalConfig = {
      scrape_interval = "10s";
      evaluation_interval = "10s";
    };
    extraFlags = [
      "--web.enable-admin-api"
    ];

    alertmanagers = [
      {
        scheme = "http";
        static_configs = [
          {
            targets = [
              "localhost:${toString config.services.prometheus.alertmanager.port}"
            ];
          }
        ];
      }
    ];

    scrapeConfigs = [
      {
        job_name = "prometheus";
        static_configs = [
          {
            targets = [
              "localhost:${toString config.services.prometheus.port}"
            ];
          }
        ];
      }
      {
        job_name = "alertmanager";
        static_configs = [
          {
            targets = [
              "localhost:${toString config.services.prometheus.alertmanager.port}"
            ];
          }
        ];
      }
      {
        job_name = "node_exporter";
        static_configs = [
          {
            targets = [
              "matrix-01.int.gk.wtf:9100"
              "nextcloud-01.int.gk.wtf:9100"
              "jellyfin-01.int.gk.wtf:9100"
              "wazuh-01.int.gk.wtf:9100"
              "blog-01.int.gk.wtf:9100"
              "mastodon-01.int.gk.wtf:9100"
              "unifi-01.int.gk.wtf:9100"
              "mc-01.int.gk.wtf:9100"
              "web-01.int.gk.wtf:9100"
              "kasm-01.int.gk.wtf:9100"
              "torrenting-01.int.gk.wtf:9100"
              "docker-01.int.gk.wtf:9100"
              "homeassistant-01.int.gk.wtf:9100"
            ];
          }
        ];
        metric_relabel_configs = [
          {
            source_labels = [
              "__name__"
              "state"
            ];
            separator = "_";
            regex = "node_systemd_unit_state_[^f].*";
            action = "drop";
          }
        ];
      }
      {
        job_name = "cadvisor";
        static_configs = [
          {
            targets = [
              "torrenting-01.int.gk.wtf:8080"
              "docker-01.int.gk.wtf:8080"
            ];
          }
        ];
      }
    ];

    ruleFiles = [
      ./prometheus-rules/embedded-exporter.yml
      ./prometheus-rules/node-exporter.yml
      ./prometheus-rules/google-cadvisor.yml
    ];
  };
}
