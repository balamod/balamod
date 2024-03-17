current_version ?= $(shell grep -e "^version =" ./Cargo.toml | cut -d"=" -f2 | sed 's/"//g' )
version ?= 0.1.12

build: compile sign installer signinstaller ##@ Make the whole shebang for macos

compile:
	@echo "Compiling..."
	@cargo build --release

sign:
	@echo "Signing..."
	@codesign -s "Developer ID Application" target/release/balamod

installer:
	@echo "Creating installer..."
	@mkdir -p target/release/bundle
	@mkdir -p target/release/pkgdata
	@cp -f target/release/balamod target/release/pkgdata
	@pkgbuild --root target/release/pkgdata --identifier org.balamod --version $$(grep -e "^version =" ./Cargo.toml | cut -d"=" -f2 | sed 's/"//g' ) --install-location /usr/local/bin target/release/bundle/bare-balamod.pkg

signinstaller:
	@echo "Signing installer..."
	@productsign --sign "Developer ID Installer" "target/release/bundle/bare-balamod.pkg" "target/release/bundle/balamod.pkg"

.PHONY: sign help bumpversion

bumpversion:
	@echo "Bumping version..."
	@sed -i '' -e "s/version = \"$(current_version)\"/version = \"$(version)\"/g" ./Cargo.toml
	@sed -i '' -e "s/$(current_version)/$(version)/g" ./README.md
	@sed -i '' -e "s/const VERSION: &'static str = \"$(current_version)\";/const VERSION: &'static str = \"$(version)\";/g" ./src/main.rs
	@echo "Version bumped to $(version)"