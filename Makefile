# Config -------------------------------------------------------------------
SRC       := src
BIN       := src.bin
DATA      := image.dat
PNG       := mandelbrot.png
GPFILE    := topng.gp

WIDTH     := 5000
HEIGHT    := 5000

ODIN      := odin
ODINFLAGS := -o:speed

.PHONY: all build image bench clean

all: build

# Rebuilds whenever any .odin file in src/ changes.
build: $(BIN)

$(BIN): $(wildcard $(SRC)/*.odin)
	$(ODIN) build $(SRC) -out:$(BIN) $(ODINFLAGS)

$(DATA): $(BIN)
	./$(BIN) png=1 width=$(WIDTH) height=$(HEIGHT) > $(DATA)

image: $(DATA)
	gnuplot $(GPFILE)

# Timed run. Uses hyperfine if available (accurate, multiple runs);
# falls back to /usr/bin/time for a single run otherwise.
bench: build
	@if command -v hyperfine >/dev/null 2>&1; then \
		hyperfine --warmup 2 --min-runs 10 \
			'./$(BIN) png=1 width=$(WIDTH) height=$(HEIGHT) > /dev/null'; \
	else \
		echo "hyperfine not found (brew install hyperfine) - single timed run:"; \
		/usr/bin/time -p ./$(BIN) png=1 width=$(WIDTH) height=$(HEIGHT) > /dev/null; \
	fi

clean:
	rm -f $(BIN) $(DATA) $(PNG)

# Add a multi-threaded version by mirroring this pattern, e.g.:
#   BIN_MT := src_mt.bin
#   $(BIN_MT): $(wildcard src_mt/*.odin)
#       $(ODIN) build src_mt -out:$(BIN_MT) $(ODINFLAGS)
#   bench-mt: BIN=$(BIN_MT)
#   bench-mt: bench
