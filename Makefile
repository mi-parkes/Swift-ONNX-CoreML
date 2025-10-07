.ONESHELL:
SHELL           =/bin/bash
MAKEFLAGS       += $(if $(VERBOSE),,--no-print-directory)
MINMAKEVERSION  =3.82
$(if $(findstring $(MINMAKEVERSION),$(firstword $(sort $(MINMAKEVERSION) $(MAKE_VERSION)))),,$(error The Makefile requires minimal GNU make version:$(MINMAKEVERSION) and you are using:$(MAKE_VERSION)))

$(MAKE_VERBOSE).SILENT:
	echo NothingAtAll

TARGET=arm64-apple-macosx15.0
BUILD_CONFIGURATION = debug

clean:
	rm -rf .build

# feat: Generate coreml model Swift class loader
z1:
	$(eval ODIR=/tmp/Generated)
	rm -rf $(ODIR)
	mkdir -p $(ODIR)
	xcrun coremlc generate Sources/classifierWrapper/Resources/GeoClassifier.mlpackage \
		$(ODIR) --language Swift
	find $(ODIR)

GeoClassifier.swift:
	$(eval ODIR=Sources/classifierWrapper)
	$(eval OFILE=$(ODIR)/GeoClassifier.swift)
	rm -fv $(OFILE)
	xcrun coremlc generate Sources/classifierWrapper/Resources/GeoClassifier.mlpackage \
		$(ODIR) --language Swift 
    
	gsed -i 's,bundle.url,Bundle.module.url,' $(OFILE)	
	ls -l $(OFILE)

GeoClassifier.mlmodelc:
	$(eval ODIR=Sources/classifierWrapper/Resources)
	$(eval OFILE=GeoClassifier.mlmodelc)
	cd $(ODIR)
	rm -frv $(OFILE)
	xcrun coremlc compile GeoClassifier.mlpackage .
	rm -rfv $(OFILE)/analytics
	ls -l $(OFILE)

check:
	$(eval IFILE=GeoClassifier.mlmodelc)
	for dir in Sources .build; do
		echo "-- Look for $(IFILE) in '$$dir'"
		find $$dir -name $(IFILE)
	done

build:
	$(if $(CLEAN),swift package clean,)
	swift build \
		--configuration $(BUILD_CONFIGURATION) \
		--triple $(TARGET) $(if $(VERBOSE),-v,) -Xswiftc -g

buildx:
	$(if $(CLEAN),swift package clean,)
	ENABLE_REMOTE_TEST=1 swift build \
		--configuration $(BUILD_CONFIGURATION) \
		--triple $(TARGET) $(if $(VERBOSE),-v,)

describe:
	$(eval ODIR=/tmp/$@)
	$(eval OFILEPREF=$(ODIR)/Swift-ONNX-CoreML)
	mkdir -p $(ODIR)
	rm -f $(OFILEPREF).svg $(OFILEPREF).mmd
	swift package describe --type mermaid | \
	gsed '/^```mermaid$$/d;/^```$$/d' | tee $(OFILEPREF).mmd
	mmdc -i $(OFILEPREF).mmd -o $(OFILEPREF).svg -c browser-config.json
	open $(OFILEPREF).svg
	ls -l $(OFILEPREF).svg

describex:
	$(eval ODIR=/tmp/describe)
	$(eval OFILEPREF=$(ODIR)/Swift-ONNX-CoreML)
	mmdc -i $(OFILEPREF).mmd \
		-o $(OFILEPREF).svg \
		-c browser-config.json
	open $(OFILEPREF).svg

#		--backgroundColor transparent \

depend:
#	swift package show-dependencies 
	ENABLE_REMOTE_TEST=1 swift package \
	show-dependencies --format dot

# swift build -Xswiftc -g -Xswiftc -debug-info-format=dwarf
# https://lldb.llvm.org/use/tutorial.html
debug-testClassifier1:
	echo breakpoint set -f main.swift -l 19
	echo breakpoint set --file main.swift --line 19
	echo br list
	echo image dump line-table main.swift
	echo image list .build/$(BUILD_CONFIGURATION)/testClassifier1
	echo r
	echo r -- argument1 value2
	arch -arm64 lldb .build/$(BUILD_CONFIGURATION)/testClassifier1

check-debug-symbols-testClassifier1:
	dsymutil -s .build/debug/testClassifier1 | grep N_OSO

run:
	.build/$(BUILD_CONFIGURATION)/testClassifier1
	if [ -f .build/debug/testClassifier2 ]; then
		.build/$(BUILD_CONFIGURATION)/testClassifier2
	fi

proj:
	open -a xcode .

# REMOTEGITURL=https://github.com/mi-parkes/Swift-ONNX-CoreML.git
REMOTEGITURL=/tmp/classifier-swift.git
GITTAG=v1.0.0

# test: Test full development cycle
#
# This commit adds a new integration test script to validate the end-to-end process, from code checkout and building targets to running the final CLI application with sample data.
full-repository-test-help:
	echo $(MAKE) create-remote-repository
	echo $(MAKE) create-local-repository
	echo $(MAKE) test-clone1
	echo $(MAKE) test-clone2

full-repository-test:
	$(MAKE) create-remote-repository
	$(MAKE) create-local-repository
	$(MAKE) test-clone1
	$(MAKE) test-clone2

# feat: Initial commit
create-local-repository:
	$(if $(CLEAN),rm -rf .git,)
	git init
	git add README.md .gitignore Makefile Package.swift Sources onnxruntime.xcframework
	git commit -m "init: Initial commit"
	git branch -M main
	git remote add origin $(REMOTEGITURL)
	git tag $(GITTAG)
	git push -u origin main  --tags

# test:	Simulate repository clone for testing
test-clone1:
	$(eval WDIR=/tmp/$@)
	rm -rf $(WDIR)
	cd /tmp
	git clone file://$(REMOTEGITURL) $@
	cd $(WDIR)
	pwd
	ls -l
	cp -r $(CURDIR)/../onnxruntime.xcframework /tmp/onnxruntime.xcframework
	$(MAKE) build

# test: Simulate cloning a specific Git reference
test-clone3:
	$(eval WDIR=/tmp/$@)
	rm -rf $(WDIR)
	cd /tmp
	git clone --branch $(GITTAG) --single-branch --depth 1 file://$(REMOTEGITURL) $@
	cd $(WDIR)
	pwd
	ls -l
	cp -r $(CURDIR)/../onnxruntime.xcframework /tmp/onnxruntime.xcframework
	$(MAKE) build

# test:	Simulate remote repository environment
create-remote-repository:
	$(eval WDIR=$(REMOTEGITURL))
	rm -rf $(WDIR)
	mkdir -p $(WDIR)
	cd $(WDIR)
	git init --bare
