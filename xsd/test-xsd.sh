#!/bin/sh
# run this script in a directory that contains DMN XML files, e.g. the DMN TCK
# if the diff shows any differences it could indicate an unintended BC break in the XSD

# setup a target dir for temporary files
TARGET_DIR="$(dirname $0)/target"
mkdir -p $TARGET_DIR

# download the official DMN 1.1 XML schema for comparison
wget 'http://www.omg.org/spec/DMN/20151101/dmn.xsd' --output-document="$TARGET_DIR/DMN11.xsd" -nc

# search all DMN files in the current directory and perform a schema validation with the DMN 1.1 and 1.2 schemas
find '(' -iname '*.dmn*.xml' -o -iname '*.dmn' ')' -type f | xargs -L 1 xmllint --schema "$TARGET_DIR/DMN11.xsd" --noout > "$TARGET_DIR/validdmn11.log" 2>&1
find '(' -iname '*.dmn*.xml' -o -iname '*.dmn' ')' -type f | xargs -L 1 xmllint --schema "$(dirname $0)/dmn.xsd" --noout > "$TARGET_DIR/validdmn12.log" 2>&1

# filter out validation errors about intended changes in DMN 1.2
grep -vf "$(dirname $0)/test-xsd-ignore-list-11.txt" "$TARGET_DIR/validdmn11.log" > "$TARGET_DIR/validdmn11.filtered.log"
grep -vf "$(dirname $0)/test-xsd-ignore-list-12.txt" "$TARGET_DIR/validdmn12.log" > "$TARGET_DIR/validdmn12.filtered.log"

# adjust lists of expected elements
sed -i 's#: This element is not expected. Expected is one of ( {http://www.omg.org/spec/DMN/20151101/dmn.xsd}elementCollection, {http://www.omg.org/spec/DMN/20151101/dmn.xsd}businessContextElement, {http://www.omg.org/spec/DMN/20151101/dmn.xsd}performanceIndicator, {http://www.omg.org/spec/DMN/20151101/dmn.xsd}organizationUnit ).#: This element is not expected. Expected is one of ( {http://www.omg.org/spec/DMN/20151101/dmn.xsd}elementCollection, {http://www.omg.org/spec/DMN/20151101/dmn.xsd}businessContextElement, {http://www.omg.org/spec/DMN/20151101/dmn.xsd}performanceIndicator, {http://www.omg.org/spec/DMN/20151101/dmn.xsd}organizationUnit, {http://www.omg.org/spec/DMN/20151101/DMNDI}DMNDI ).#' "$TARGET_DIR/validdmn11.filtered.log"
sed -i 's#: Missing child element(s). Expected is one of ( {http://www.omg.org/spec/DMN/20151101/dmn.xsd}requiredDecision, {http://www.omg.org/spec/DMN/20151101/dmn.xsd}requiredInput ).#: Missing child element(s). Expected is one of ( {http://www.omg.org/spec/DMN/20151101/dmn.xsd}description, {http://www.omg.org/spec/DMN/20151101/dmn.xsd}extensionElements, {http://www.omg.org/spec/DMN/20151101/dmn.xsd}requiredDecision, {http://www.omg.org/spec/DMN/20151101/dmn.xsd}requiredInput ).#' "$TARGET_DIR/validdmn11.filtered.log"

# compare the filtered log files
colordiff "$TARGET_DIR/validdmn11.filtered.log" "$TARGET_DIR/validdmn12.filtered.log"