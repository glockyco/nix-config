{
  programs.gh = {
    enable = true;

    settings = {
      # Use the SSH key already served by Secretive rather than making gh
      # manage a second credential. `gh` then shells out to git over SSH and
      # authentication goes through the Secure Enclave like everything else.
      git_protocol = "ssh";

      editor = "zed --wait";
    };
  };
}
