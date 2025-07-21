{
  pkgs,
  lib,
  storageDriver ? null,
  ...
}:

assert lib.asserts.assertOneOf "storageDriver" storageDriver [
  null
  "aufs"
  "btrfs"
  "devicemapper"
  "overlay"
  "overlay2"
  "zfs"
];

{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    inherit storageDriver;
    autoPrune.enable = true;
  };

  environment.systemPackages = with pkgs; [
    docker
    docker-compose
    minikube
    kubectl
  ];
}
