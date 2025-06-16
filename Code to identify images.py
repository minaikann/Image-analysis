import torch
import torchvision
import numpy as np
import matplotlib.pyplot as plt
import cv2
import os
import sys

# Add SAM path
sys.path.append("..")
from segment_anything import sam_model_registry, SamAutomaticMaskGenerator

# ----------- Configuration ------------
MODEL_TYPE = "vit_h"
CHECKPOINT_PATH = "sam_vit_h_4b8939 (1).pth"
DEVICE = "cpu"

# SAM settings
MASK_GENERATOR_CONFIG = {
    "points_per_side": 32,
    "pred_iou_thresh": 0.9,
    "stability_score_thresh": 0.96,
    "crop_n_layers": 1,
    "crop_n_points_downscale_factor": 2,
    "min_mask_region_area": 100,
}
# --------------------------------------


def load_sam_model(model_type, checkpoint_path, device="cpu"):
    sam = sam_model_registry[model_type](checkpoint=checkpoint_path)
    sam.to(device=device)
    return sam


def show_anns(anns, ax):
    if len(anns) == 0:
        return
    sorted_anns = sorted(anns, key=lambda x: x['area'], reverse=True)
    for ann in sorted_anns:
        m = ann['segmentation']
        img = np.ones((m.shape[0], m.shape[1], 3))
        color_mask = np.random.random((1, 3)).tolist()[0]
        for i in range(3):
            img[:, :, i] = color_mask[i]
        ax.imshow(np.dstack((img, m * 0.35)))


def generate_masks(image, mask_generator):
    return mask_generator.generate(image)


def process_image(image_path, mask_generator, output_dir, save_masks=False):
    filename = os.path.basename(image_path)
    name, _ = os.path.splitext(filename)

    image = cv2.imread(image_path)
    if image is None:
        print(f"Failed to load {image_path}")
        return
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

    # Generate masks
    masks = generate_masks(image, mask_generator)

    # Plot and save overlay
    fig, ax = plt.subplots(figsize=(10, 10))
    ax.imshow(image)
    show_anns(masks, ax)
    ax.axis('off')

    overlay_path = os.path.join(output_dir, f"{name}_with_masks.jpg")
    fig.savefig(overlay_path, bbox_inches='tight', pad_inches=0, dpi=300)
    plt.close(fig)

    print(f"Saved: {overlay_path}")

    # Optionally save binary masks
    """if save_masks:
        masks_dir = os.path.join(output_dir, f"{name}_masks")
        os.makedirs(masks_dir, exist_ok=True)
        for i, mask in enumerate(masks):
            mask_img = (mask['segmentation'].astype(np.uint8)) * 255
            out_path = os.path.join(masks_dir, f"mask_{i}.tif")
            cv2.imwrite(out_path, mask_img)"""


def process_folder(input_folder, output_folder, save_masks=False):
    os.makedirs(output_folder, exist_ok=True)
    sam_model = load_sam_model(MODEL_TYPE, CHECKPOINT_PATH, DEVICE)
    mask_generator = SamAutomaticMaskGenerator(sam_model, **MASK_GENERATOR_CONFIG)

    supported_exts = (".jpg", ".jpeg", ".png", ".tif", ".tiff")
    image_files = [f for f in os.listdir(input_folder) if f.lower().endswith(supported_exts)]

    if not image_files:
        print("No valid images found in folder.")
        return

    for img_file in image_files:
        img_path = os.path.join(input_folder, img_file)
        process_image(img_path, mask_generator, output_folder, save_masks=save_masks)


# ---------- Example usage --------------
if __name__ == "__main__":
    input_dir = "tadpoles_length"    # Replace with your actual input folder
    output_dir = "sam_results" # Replace with your desired output folder
    process_folder(input_dir, output_dir, save_masks=True)  # Set to False if you don't want individual masks
