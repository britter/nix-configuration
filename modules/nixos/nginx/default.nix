_: {
  services.nginx.virtualHosts.default = {
    serverName = "_";
    default = true;
    listen = [
      {
        addr = "0.0.0.0";
        port = 80;
      }
      {
        addr = "[::0]";
        port = 80;
      }
      {
        addr = "0.0.0.0";
        port = 443;
      }
      {
        addr = "[::0]";
        port = 443;
      }
    ];
    locations."/" = {
      return = 404;
    };
  };
}
