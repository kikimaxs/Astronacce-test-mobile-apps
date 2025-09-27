import { Router } from 'express';
import { 
  getUsers, 
  getUserById, 
  createUser, 
  updateUser, 
  deleteUser 
} from '../controllers/userController';
import { authenticateToken } from '../middleware/auth';

const router = Router();

// All user routes require authentication
router.use(authenticateToken);

// GET routes
router.get('/', getUsers);
router.get('/:id', getUserById);

// POST routes
router.post('/', createUser);

// PUT routes
router.put('/:id', updateUser);

// DELETE routes
router.delete('/:id', deleteUser);

export default router;