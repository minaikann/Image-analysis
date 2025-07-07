// --- Select input/output folder ---
inputDir = getDirectory("Choose your input folder");
outputDir = inputDir + "Processed/";
if (!File.exists(outputDir)) File.makeDirectory(outputDir);
summaryPath = outputDir + "eyeDistances_from_row3.csv";

// --- Initialize CSV if needed ---
if (!File.exists(summaryPath)) {
    File.saveString("Image,EyeDistance(pixels)\n", summaryPath);
}

setBatchMode(true);
list = getFileList(inputDir);

for (i = 0; i < list.length; i++) {
    filename = list[i];
    nameLower = toLowerCase(filename);
    if (!(endsWith(nameLower, ".tif") || endsWith(nameLower, ".tiff"))) continue;

    // Open image with Bio-Formats Importer in colorized mode
    run("Bio-Formats Importer", "open=[" + inputDir + filename + "] autoscale color_mode=Colorized view=Hyperstack stack_order=XYCZT");

    // Get base name without extension
    baseName = getTitle();
    dotIndex = lastIndexOf(baseName, ".");
    if (dotIndex != -1) {
        baseName = substring(baseName, 0, dotIndex);
    }
    rename("Eyes");

    // --- Split & merge channels into composite ---
    run("Split Channels");
    run("Merge Channels...", "c1=C1-Eyes c2=C2-Eyes c3=C3-Eyes c4=C4-Eyes create");
    rename("Composite");

    // --- Process channel 1 ---
    run("Duplicate...", "title=ProcessedC1");
    selectImage("ProcessedC1");
    run("8-bit");
    run("Median...", "radius=6");
    setAutoThreshold("Default dark no-reset");
    setOption("BlackBackground", true);
    run("Convert to Mask");

    run("Set Measurements...", "centroid redirect=None decimal=3");
    run("Analyze Particles...", "size=5000-Infinity pixel circularity=0.35-1.00 display add slice");

    roiCount = roiManager("count");
    if (roiCount < 2) {
        print("[" + baseName + "] Not enough ROIs, skipping...");
        close("*");
        run("Clear Results");
        roiManager("reset");
        continue;
    }

    // Get centroid coordinates of first two ROIs
    x1 = round(getResult("X", 0));
    y1 = round(getResult("Y", 0));
    x2 = getResult("X", 1);
    y2 = getResult("Y", 1);
    dx = x2 - x1;
    dy = y2 - y1;
    eyeDistance = round(sqrt(dx*dx + dy*dy));

    // Add eye distance measurement to Results table (new row)
    rowIndex = nResults;
    setResult("Label", rowIndex, "Eye Distance");
    setResult("X", rowIndex, eyeDistance);
    setResult("Y", rowIndex, "Pixels");
    updateResults();

    // Show line and add to ROI Manager
	selectImage("Composite");
	makeLine(x1, y1, x2, y2);
	roiManager("Add");
	roiManager("Show All");
	run("Flatten");

	saveAs("Tiff", outputDir + baseName + ".tif");


    // --- Extract the X column value from the 3rd row (index 2) of the Results table ---
    if (nResults > 2) {
        eyeDistFromRow3 = getResult("X", 2);
        File.append(baseName + "," + eyeDistFromRow3 + "\n", summaryPath);
    } else {
        print("[" + baseName + "] Less than 3 rows in results table; skipping row 3 extraction.");
    }

    // Cleanup
    close("*");
    run("Clear Results");
    roiManager("reset");
}

setBatchMode(false);
print("✅ Done! Eye distances from 3rd row saved to: " + summaryPath);
