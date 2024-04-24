{pkgs, ...}: {
  programs.git = {
    includes = [
      {
        condition = "gitdir:~/github/gradlex-org/";
        contents = {
          user.email = "benedikt@gradlex.org";
          user.signingKey = "757DE51A2FD1489D";
        };
      }
      {
        condition = "gitdir:~/github/apache/";
        contents = {
          user.email = "britter@apache.org";
          user.signingKey = "9DAADC1C9FCC82D0";
        };
      }
    ];
  };
}
