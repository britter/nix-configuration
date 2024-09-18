_: {
  services.nginx.virtualHosts.default = {
    serverName = "_";
    default = true;
    locations."/" = {
      return = 404;
    };
  };
}
