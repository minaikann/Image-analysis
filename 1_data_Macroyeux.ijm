// Get base name from the original opened image before renaming
baseName = getTitle();
dotIndex = lastIndexOf(baseName, ".");
if (dotIndex != -1) {
    baseName = substring(baseName, 0, dotIndex);
}

run("Split Channels");
run("Duplicate...", "title=dub duplicate channels=");
selectImage("dub");
setOption("ScaleConversions", true);
run("8-bit");
run("Grays");
run("Median...", "radius=3");
setAutoThreshold("Default dark 16-bit no-reset");

//setThreshold(110, 255);
setOption("BlackBackground", true);
run("Convert to Mask");
run("Analyze Particles...", "size=5000-Infinity display clear include summarize add record");

// ✅ Save the 'dub' image as a TIF with base name
saveAs("Tiff", "C:/Users/Mina/Desktop/Test output/Processedyeux_" + baseName + ".tif");
saveAs("Results", "C:/Users/Mina/Desktop/Test output/Resultsyeux_" + baseName + ".csv");
close;
run("Close");
