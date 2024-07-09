# Shared variables, should be exported
export DRY=false

# Variables for install.sh, `export` not needed

rav1e_enable=true
rav1e_opts=()

cosmocc_enable=true
cosmocc_opts=()

ffmpeg_enable=true
ffmpeg_source_only=true  ## Build libs from source
ffmpeg_opts=(
    # Some dependencies are always installed and not included here, such as libmp3lame
    --enable-fontconfig
    --enable-libx264
    --enable-libx265
    --enable-libvpx
    --enable-libfdk-aac
    --enable-libopus
    --enable-libsvtav1
    --enable-libdav1d
    --enable-libvmaf
    --enable-libsrt
    --enable-libbluray
    --enable-libplacebo  # A library for GPU-accelerated video/image rendering primitives
    --enable-librav1e  # Also enables rav1e, finer detail preservations over libsvtav1
    --enable-libaom  # Slow and annoying to build, just use librav1e

    ### Features below may require manually adding dependencies

    ## Extra codecs
    --enable-libwebp
    --enable-libjxl  # JPEG XL, a new image compression standard
    --enable-librsvg
    --enable-libzimg  # Zimg, a lightweight image processing library
    # --enable-libharfbuzz  # OpenType text shaping engine
    # --enable-libgsm  # GSM speech codec
    # --enable-libopencore_amrnb  # OpenCORE Adaptive Multi-Rate Narrow-Band, an audio codec
    # --enable-libopencore_amrwb  # OpenCORE Adaptive Multi-Rate Wide-Band, an audio codec
    # --enable-libopenjpeg
    # --enable-libspeex  # Speex, an audio codec
    # --enable-libtheora  # Theora, a video codec
    # --enable-libxvid  # Xvid, an MPEG-4 video codec

    ## Extra plugins
    --enable-gmp  # GNU Multiple Precision Arithmetic Library
    --enable-libsnappy  # Snappy, a fast compressor/decompressor
    --enable-libbs2b  # Bauer stereophonic-to-binaural DSP
    --enable-librubberband  # Rubber Band Audio Time Stretcher
    --enable-libsoxr  # SoX Resampler, a high-quality, one-dimensional sample-rate converter
    --enable-libdrm  # Direct Rendering Manager
    # --enable-libfribidi  # Free Implementation of the Unicode Bidirectional Algorithm, text rendering related
    # --enable-libvidstab # Video stabilization library
    # --enable-frei0r  # An open-source cross-platform real-time video effects plugin system
    # --enable-ladspa  # Linux Audio Developer's Simple Plugin API
    # --enable-libmodplug  # ModPlug, a module file format library
    # --enable-libopenmpt  # OpenMPT, a module file format library
    # --enable-libiec61883  # IEC 61883, standard for streaming audio and video over FireWire
    # --enable-libpulse  # PulseAudio audio server
    # --enable-libjack  # JACK Audio Connection Kit
    # --enable-libxml2  # XML C parser and toolkit
    # --enable-libssh
    # --enable-libxcb  # X C Binding, a library for interfacing with X11

    ## OS specific
    --enable-libv4l2  # Video4Linux2
    # --enable-avisynth  # Windows only

    ## Platform specific
    --enable-vulkan
    # --enable-nvdec  # FU NVIDIA
    # --enable-nvenc
    # --enable-cuda-llvm
    # --enable-amf  # AMD Advanced Media Framework
    # --enable-libmfx  # Intel Media SDK
    # --enable-opencl
    # --enable-opengl

    ## Misc
    --enable-lto
    --disable-debug
    # --enable-shared
    # --disable-stripping
)

aria2_enable=false
aria2_opts=()

hashcat_enable=true
hashcat_opts=()

john_enable=true
john_opts=()
