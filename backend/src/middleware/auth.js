const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');

const auth = (roles = []) => {
  return (req, res, next) => {
    try {
      const token = req.headers.authorization?.split(' ')[1];

      if (!token) {
        return res.status(401).json({ message: 'No token provided' });
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret_key');

      if (roles.length && !roles.includes(decoded.role)) {
        return res.status(403).json({ message: 'Forbidden' });
      }

      // Ensure userId is properly converted to ObjectId for database queries
      // Store both the string (for JWT comparisons) and ObjectId (for DB queries)
      req.user = {
        ...decoded,
        userId: new mongoose.Types.ObjectId(decoded.id),
        id: decoded.id
      };
      
      next();
    } catch (error) {
      console.error('Auth error:', error.message);
      return res.status(401).json({ message: 'Invalid token' });
    }
  };
};

module.exports = auth;
