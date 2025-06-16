// Get the base name of the current image without extension
baseName = getTitle();
dotIndex = lastIndexOf(baseName, ".");
if (dotIndex != -1) {
    baseName = substring(baseName, 0, dotIndex);
}


run("Duplicate...", "title=Dub duplicate channels=1");
run("Enhance Contrast...", "saturated=0.35");
run("Grays");
run("Median...", "radius=4");
setMinAndMax(0.00, 0.88);setAutoThreshold("Default dark no-reset");

//run("Threshold...");
setOption("BlackBackground", true);
run("Convert to Mask");
run("Analyze Particles...", "size=5000-Infinity display clear include summarize add record");

// Correct path: use double backslashes OR forward slashes
savePath = "C:/Users/Mina/PycharmProjects/PythonProject/les yeux/Results_" + baseName + ".csv";
saveAs("Results", savePath);
close;

run("Close");
