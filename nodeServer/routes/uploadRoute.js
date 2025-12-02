import express from "express";
import multer from "multer";
import cloudinary from "./cloudinary.js";

const router = express.Router();
const upload = multer({ dest: "uploads/" });

router.post("/upload-foto", upload.single("foto"), async (req, res) => {
  try {
    const hasil = await cloudinary.uploader.upload(req.file.path, {
      folder: "kost-kostan"
    });

    return res.json({
      status: "success",
      url: hasil.secure_url
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

export default router;
