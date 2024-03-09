# Shared variables, should be exported
export DRY=false
export QUIET=false

# Variables for install.sh, `export` not needed
rav1e_enable=false  # Also enabled by ffmpeg if --enable-librav1e is set
rav1e_opts=(-cinstall)

cosmocc_enable=true
cosmocc_opts=()

ffmpeg_enable=true
ffmpeg_source_only=true  ## Build libs from source
ffmpeg_opts=(
    --enable-libx264
    --enable-libx265
    --enable-libvpx
    --enable-libfdk-aac
    --enable-libopus
    # --enable-libaom
    --enable-libsvtav1
    --enable-libdav1d
    --enable-libvmaf
    --enable-librav1e
)
