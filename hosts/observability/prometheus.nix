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
              "fw.int.gk.wtf:9100"
              "pve.int.gk.wtf:9100"
              "truenas.int.gk.wtf:9100"
              "docker.int.gk.wtf:9100"
              "t.int.gk.wtf:9100"
              "web.int.gk.wtf:9100"
              "mastodon.int.gk.wtf:9100"
              "blog.int.gk.wtf:9100"
              "jellyfin.int.gk.wtf:9100"
              "cloud.int.gk.wtf:9100"
              "caddy.int.gk.wtf:9100"
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
              "t.int.gk.wtf:8080"
              "docker.int.gk.wtf:8080"
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
