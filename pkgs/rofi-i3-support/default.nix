{ i3
, jq
, lib
, stdenvNoCC
, withSwm ? false
  # TODO: once swm is packaged in Soxin, add it as a dependency
}:

stdenvNoCC.mkDerivation rec {
  pname = "rofi-i3-support";
  version = "0.0.1";

  src = ./.;

  installPhase = ''
    install -d -m755 $out/bin $out/lib

    substitute $src/i3-move-container.sh $out/bin/i3-move-container \
      --subst-var-by i3-msg_bin ${i3}/bin/i3-msg \
      --subst-var-by jq_bin ${jq}/bin/jq \
      --subst-var-by out_dir $out

    substitute $src/i3-rename-workspace.sh $out/bin/i3-rename-workspace \
      --subst-var-by i3-msg_bin ${i3}/bin/i3-msg \
      --subst-var-by jq_bin ${jq}/bin/jq \
      --subst-var-by out_dir $out

    substitute $src/i3-swap-workspaces.sh $out/bin/i3-swap-workspaces \
      --subst-var-by i3-msg_bin ${i3}/bin/i3-msg \
      --subst-var-by jq_bin ${jq}/bin/jq \
      --subst-var-by out_dir $out

    substitute $src/i3-switch-workspaces.sh $out/bin/i3-switch-workspaces \
      --subst-var-by i3-msg_bin ${i3}/bin/i3-msg \
      --subst-var-by jq_bin ${jq}/bin/jq \
      --subst-var-by out_dir $out

    substitute $src/list-workspaces.sh $out/lib/list-workspaces.sh \
      --subst-var-by i3-msg_bin ${i3}/bin/i3-msg \
      --subst-var-by jq_bin ${jq}/bin/jq \
      --subst-var-by out_dir $out

    chmod 755 $out/bin/*
  '';

  meta = with lib; {
    # TODO: For some reason i3's platform is set to all of them.
    # platforms = lists.intersectLists i3.meta.platforms jq.meta.platforms;
    platforms = platforms.linux;
    description = "Rofi support for i3.";
    maintainers = with maintainers; [ kalbasit ];
  };
}
