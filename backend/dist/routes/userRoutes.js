"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const userController_1 = require("../controllers/userController");
const auth_1 = require("../middleware/auth");
const router = (0, express_1.Router)();
// All user routes require authentication
router.use(auth_1.authenticateToken);
// GET routes
router.get('/', userController_1.getUsers);
router.get('/:id', userController_1.getUserById);
// POST routes
router.post('/', userController_1.createUser);
// PUT routes
router.put('/:id', userController_1.updateUser);
// DELETE routes
router.delete('/:id', userController_1.deleteUser);
exports.default = router;
//# sourceMappingURL=userRoutes.js.map