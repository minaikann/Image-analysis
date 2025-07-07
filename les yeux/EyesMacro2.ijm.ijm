// Get the base name of the current image without extension
baseName = getTitle();
dotIndex = lastIndexOf(baseName, ".");
if (dotIndex != -1) {
    baseName = substring(baseName, 0, dotIndex);
}

// Rename the original image for clarity
rename("Eyes");

// --- Split all channels ---
run("Split Channels");

// --- Merge all 5 channels into a composite image for later ROI visualization ---
run("Merge Channels...", "c1=C1-Eyes c2=C2-Eyes c3=C3-Eyes c4=C4-Eyes create");
rename("Composite"); // This will be used later to show ROIs

// --- Process only Channel 1 (C1) to detect eyes ---
run("Duplicate...", "title=ProcessedC1");

selectImage("ProcessedC1");
setOption("ScaleConversions", true);
run("8-bit");
run("Median...", "radius=6");

// Threshold and convert to binary mask
setAutoThreshold("Default dark no-reset");
//run("Threshold...");
//setThreshold(96, 255);
setOption("BlackBackground", true);
run("Convert to Mask");

// Analyze particles
run("Set Measurements...", "centroid redirect=None decimal=3");
run("Analyze Particles...", "size=6000-Infinity pixel circularity=0.19-1.00 display add slice");

// Check if at least 2 ROIs are found
roiCount = roiManager("count");
if (roiCount < 2) {
    exit("Not enough ROIs detected (found " + roiCount + ").");
}

// Get centroid coordinates of the first two ROIs
x1 = round(getResult("X", 0));
x2 = getResult("X", 1);
y1 = round(getResult("Y", 0));
y2 = getResult("Y", 1);

// Compute Euclidean distance between eyes
dx = x2 - x1;
dy = y2 - y1;
eyeDistance = sqrt(dx * dx + dy * dy);

// Save measurement in the results table
rowIndex = nResults;
setResult("Label", rowIndex, "Eye Distance");
setResult("X", rowIndex, eyeDistance);
setResult("Y", rowIndex, "Pixels");
updateResults();

// Show line and ROIs on the merged 5-channel image
selectImage("Composite");
makeLine(x1, y1, x2, y2);
roiManager("Add");
roiManager("Show All");

// Save results to CSV
savePath = "C:/Users/Mina/Desktop/PythonProject/ALL_YEUX/BPSprocessed/Results/Results_" + baseName + ".csv";
saveAs("Results", savePath);
