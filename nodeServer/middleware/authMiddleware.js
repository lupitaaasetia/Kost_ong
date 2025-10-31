const jwt = require('jsonwebtoken');

const verifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'] || req.headers['Authorization'];
  if (!authHeader) return res.status(401).json({ message: 'No token provided' });

  const token = authHeader.startsWith('Bearer ') ? authHeader.split(' ')[1] : authHeader;
  if (!token) return res.status(401).json({ message: 'Invalid token' });

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ message: 'Token invalid', error: err.message });
  }
};

module.exports = verifyToken;
