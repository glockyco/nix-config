{
  desktop = {
    tag = "tag:desktop";
    lifecycle = "durable";
    purpose = "Durable personal desktop.";
  };

  desktop-ac = {
    tag = "tag:desktop-ac";
    lifecycle = "durable";
    purpose = "Second personal Windows desktop, configured by hand.";
  };

  korolev = {
    tag = "tag:korolev";
    lifecycle = "durable";
    purpose = "Work laptop on native Windows, configured outside Nix.";
  };

  macbook-air = {
    tag = "tag:macbook-air";
    lifecycle = "temporary";
    purpose = "Access to PhD thesis and TOSEM paper research results until the borrowed machine is returned.";
  };
}
