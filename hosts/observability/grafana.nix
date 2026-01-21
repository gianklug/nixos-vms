{ config, pkgs, ... }:
let
  idpUrl = "https://idp.gk.wtf";
in
{
  services.grafana = {
    enable = true;
    settings = {
      server = {
        domain = "grafana.gk.wtf";
        root_url = "https://%(domain)s/";
        http_addr = "0.0.0.0";
        http_port = 3000;
      };
      auth = {
        signout_redirect_url = "${idpUrl}/application/o/grafana/end-session/";
        oauth_auto_login = true;
      };
      "auth.generic_oauth" = {
        name = "authentik";
        enabled = true;
        client_id = "grafana";
        scopes = "openid email profile";
        auth_url = "${idpUrl}/application/o/authorize/";
        token_url = "${idpUrl}/application/o/token/";
        api_url = "${idpUrl}/application/o/userinfo/";
        role_attribute_path = "contains(groups, 'authentik Admins') && 'Admin' || 'Viewer'";
      };
    };
    provision = {
      enable = true;

      # Creates a *mutable* dashboard provider, pulling from /etc/grafana-dashboards.
      # With this, you can manually provision dashboards from JSON with `environment.etc` like below.
      dashboards.settings.providers = [
        {
          name = "my dashboards";
          disableDeletion = true;
          options = {
            path = "/etc/grafana-dashboards";
            foldersFromFilesStructure = true;
          };
        }
      ];

      datasources.settings.datasources = [
        # Provisioning a built-in data source
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
          isDefault = true;
          editable = false;
        }
        {
          name = "Alertmanager";
          type = "alertmanager";
          url = "http://localhost:${toString config.services.prometheus.alertmanager.port}";
          editable = false;
          jsonData = {
            implementation = "prometheus";
          };
        }
      ];
    };
  };

  # see `dashboards.settings.providers` above
  environment.etc."grafana-dashboards/1860-node-exporter-full.json".source = builtins.fetchurl {
    url = "https://grafana.com/api/dashboards/1860/revisions/42/download";
    sha256 = "a4d827eb1819044bba2d6d257347175f6811910f2583fadeaf7e123c4df2125e";
  };
  environment.etc."grafana-dashboards/19792-cadvisor-dashboard.json".source = builtins.fetchurl {
    url = "https://grafana.com/api/dashboards/19792/revisions/6/download";
    sha256 = "96348d7c68e6d29ced3ba9a8da4358b8605be6815be52daf6d8be85a44f94971";
  };

  systemd.services.grafana.environment = {
    GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET =
      "$__file{${config.age.secrets.authentik-oauth-client-secret.path}}";
  };  
}
