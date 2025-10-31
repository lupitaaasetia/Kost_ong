const express = require('express');
const router = express.Router();
const Kost = require('../models/Kost');

router.get('/', async (req, res) => {
  try {
    const list = await Kost.find({}).sort({ createdAt: -1 });
    res.json(list);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

router.get('/:kost_id', async (req, res) => {
  try {
    const { kost_id } = req.params;
    const k = await Kost.findById(kost_id);
    if (!k) return res.status(404).json({ message: 'Kost not found' });
    res.json(k);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const data = req.body;
    const k = await Kost.create(data);
    res.json(k);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;
