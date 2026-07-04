import math
import tkinter as tk
from tkinter import filedialog, messagebox

from PIL import Image, ImageTk


class ColorLabPickerApp:
    def __init__(self, root):
        self.root = root
        self.root.title("CIELAB Image Picker")

        self.original_image = None
        self.display_image = None
        self.photo_image = None
        self.scale = 1.0
        self.points = []

        self.mode = tk.StringVar(value="single")

        self.build_ui()

    def build_ui(self):
        toolbar = tk.Frame(self.root, padx=10, pady=8)
        toolbar.pack(fill=tk.X)

        tk.Button(toolbar, text="Open Image", command=self.open_image).pack(side=tk.LEFT)

        tk.Radiobutton(
            toolbar,
            text="Single CIELAB",
            variable=self.mode,
            value="single",
            command=self.reset_points,
        ).pack(side=tk.LEFT, padx=(16, 0))

        tk.Radiobutton(
            toolbar,
            text="Delta E",
            variable=self.mode,
            value="delta",
            command=self.reset_points,
        ).pack(side=tk.LEFT, padx=(8, 0))

        tk.Button(toolbar, text="Clear Points", command=self.reset_points).pack(
            side=tk.LEFT, padx=(16, 0)
        )

        self.canvas = tk.Canvas(self.root, width=900, height=600, bg="#f2f2f2")
        self.canvas.pack(fill=tk.BOTH, expand=True, padx=10, pady=(0, 8))
        self.canvas.bind("<Button-1>", self.handle_click)

        self.result_text = tk.Text(self.root, height=8, padx=8, pady=8)
        self.result_text.pack(fill=tk.X, padx=10, pady=(0, 10))
        self.write_result("Open an image, then click on the image.")

    def open_image(self):
        file_path = filedialog.askopenfilename(
            title="Open image",
            filetypes=[
                ("Image files", "*.jpg *.jpeg *.png *.bmp *.tif *.tiff"),
                ("All files", "*.*"),
            ],
        )

        if not file_path:
            return

        self.original_image = Image.open(file_path).convert("RGB")
        self.reset_points()
        self.render_image()
        self.write_result("Image loaded. Click a point on the image.")

    def render_image(self):
        if self.original_image is None:
            return

        max_width = max(self.canvas.winfo_width(), 900)
        max_height = max(self.canvas.winfo_height(), 600)
        image_width, image_height = self.original_image.size

        self.scale = min(max_width / image_width, max_height / image_height, 1.0)
        display_size = (
            max(1, int(image_width * self.scale)),
            max(1, int(image_height * self.scale)),
        )

        self.display_image = self.original_image.resize(display_size, Image.LANCZOS)
        self.photo_image = ImageTk.PhotoImage(self.display_image)

        self.canvas.delete("all")
        self.canvas.config(width=display_size[0], height=display_size[1])
        self.canvas.create_image(0, 0, image=self.photo_image, anchor=tk.NW)

    def handle_click(self, event):
        if self.original_image is None:
            messagebox.showinfo("No image", "Please open an image first.")
            return

        image_width, image_height = self.original_image.size
        x = min(max(int(event.x / self.scale), 0), image_width - 1)
        y = min(max(int(event.y / self.scale), 0), image_height - 1)

        lab = rgb_to_lab(self.original_image.getpixel((x, y)))
        self.points.append((x, y, lab))

        if self.mode.get() == "single":
            self.points = [(x, y, lab)]
            self.draw_points()
            self.write_result(format_single_result(x, y, lab))
            return

        if len(self.points) > 2:
            self.points = [(x, y, lab)]

        self.draw_points()

        if len(self.points) == 1:
            self.write_result(format_single_result(x, y, lab) + "\n\nClick the second point.")
        elif len(self.points) == 2:
            self.write_result(format_delta_result(self.points[0], self.points[1]))

    def draw_points(self):
        self.render_image()

        colors = ["red", "blue"]
        for index, (x, y, _) in enumerate(self.points):
            canvas_x = x * self.scale
            canvas_y = y * self.scale
            radius = 6
            color = colors[index % len(colors)]

            self.canvas.create_oval(
                canvas_x - radius,
                canvas_y - radius,
                canvas_x + radius,
                canvas_y + radius,
                outline=color,
                width=3,
            )
            self.canvas.create_text(
                canvas_x + 12,
                canvas_y - 12,
                text=str(index + 1),
                fill=color,
                font=("Arial", 14, "bold"),
            )

        if len(self.points) == 2:
            x1, y1, _ = self.points[0]
            x2, y2, _ = self.points[1]
            self.canvas.create_line(
                x1 * self.scale,
                y1 * self.scale,
                x2 * self.scale,
                y2 * self.scale,
                fill="yellow",
                width=2,
            )

    def reset_points(self):
        self.points = []
        if self.original_image is not None:
            self.render_image()
        self.write_result("Points cleared.")

    def write_result(self, text):
        self.result_text.delete("1.0", tk.END)
        self.result_text.insert(tk.END, text)


def rgb_to_lab(rgb):
    r, g, b = [channel / 255.0 for channel in rgb]
    r, g, b = [srgb_to_linear(channel) for channel in (r, g, b)]

    x = r * 0.4124564 + g * 0.3575761 + b * 0.1804375
    y = r * 0.2126729 + g * 0.7151522 + b * 0.0721750
    z = r * 0.0193339 + g * 0.1191920 + b * 0.9503041

    x /= 0.95047
    y /= 1.00000
    z /= 1.08883

    fx, fy, fz = [lab_pivot(value) for value in (x, y, z)]

    l_value = 116 * fy - 16
    a_value = 500 * (fx - fy)
    b_value = 200 * (fy - fz)

    return (l_value, a_value, b_value)


def srgb_to_linear(value):
    if value <= 0.04045:
        return value / 12.92
    return ((value + 0.055) / 1.055) ** 2.4


def lab_pivot(value):
    epsilon = 216 / 24389
    kappa = 24389 / 27

    if value > epsilon:
        return value ** (1 / 3)
    return (kappa * value + 16) / 116


def delta_e_76(lab_one, lab_two):
    return math.sqrt(sum((first - second) ** 2 for first, second in zip(lab_one, lab_two)))


def format_single_result(x, y, lab):
    return (
        f"Point: ({x}, {y})\n"
        f"L* = {lab[0]:.2f}\n"
        f"a* = {lab[1]:.2f}\n"
        f"b* = {lab[2]:.2f}"
    )


def format_delta_result(point_one, point_two):
    x1, y1, lab_one = point_one
    x2, y2, lab_two = point_two
    delta_e = delta_e_76(lab_one, lab_two)

    return (
        f"Point 1: ({x1}, {y1})\n"
        f"L* = {lab_one[0]:.2f}, a* = {lab_one[1]:.2f}, b* = {lab_one[2]:.2f}\n\n"
        f"Point 2: ({x2}, {y2})\n"
        f"L* = {lab_two[0]:.2f}, a* = {lab_two[1]:.2f}, b* = {lab_two[2]:.2f}\n\n"
        f"Delta E 76 = {delta_e:.2f}"
    )


if __name__ == "__main__":
    app_root = tk.Tk()
    ColorLabPickerApp(app_root)
    app_root.mainloop()
