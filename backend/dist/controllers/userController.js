"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteUser = exports.updateUser = exports.createUser = exports.getUserById = exports.getUsers = void 0;
// Remove the default admin user - start with empty array
let users = [];
const getUsers = (req, res) => {
    try {
        const { search, page = 1, limit = 10 } = req.query;
        const ownerId = req.userId; // ID user yang sedang login
        // Filter users berdasarkan owner
        let filteredUsers = users.filter(user => user.ownerId === ownerId);
        // Search functionality
        if (search) {
            const searchTerm = search.toLowerCase();
            filteredUsers = filteredUsers.filter(user => user.name.toLowerCase().includes(searchTerm) ||
                user.email.toLowerCase().includes(searchTerm));
        }
        // Pagination
        const startIndex = (Number(page) - 1) * Number(limit);
        const endIndex = startIndex + Number(limit);
        const paginatedUsers = filteredUsers.slice(startIndex, endIndex);
        res.json({
            users: paginatedUsers,
            pagination: {
                currentPage: Number(page),
                totalPages: Math.ceil(filteredUsers.length / Number(limit)),
                totalUsers: filteredUsers.length,
                hasNext: endIndex < filteredUsers.length,
                hasPrev: startIndex > 0
            }
        });
    }
    catch (error) {
        res.status(500).json({ error: 'Internal server error' });
    }
};
exports.getUsers = getUsers;
const getUserById = (req, res) => {
    try {
        const id = parseInt(req.params.id);
        const ownerId = req.userId;
        // Cari user berdasarkan ID dan owner
        const user = users.find(u => u.id === id && u.ownerId === ownerId);
        if (!user) {
            res.status(404).json({ error: 'User not found' });
            return;
        }
        res.json(user);
    }
    catch (error) {
        res.status(500).json({ error: 'Internal server error' });
    }
};
exports.getUserById = getUserById;
const createUser = (req, res) => {
    try {
        const { name, email, phone, address, avatar } = req.body;
        const ownerId = req.userId;
        // Validation
        if (!name || !email) {
            res.status(400).json({ error: 'Name and email are required' });
            return;
        }
        // Check if email already exists untuk owner yang sama
        const existingUser = users.find(u => u.email === email && u.ownerId === ownerId);
        if (existingUser) {
            res.status(409).json({ error: 'Email already exists' });
            return;
        }
        // Generate new ID - more robust approach
        const existingIds = users.map(u => u.id).filter(id => typeof id === 'number' && !isNaN(id));
        const newId = existingIds.length > 0 ? Math.max(...existingIds) + 1 : 1;
        // Create new user dengan ownerId
        const newUser = {
            id: newId,
            name: name.toString(),
            email: email.toString(),
            phone: phone?.toString() || '',
            address: address?.toString() || '',
            avatar: avatar?.toString() || '',
            ownerId: ownerId, // Tambahkan ownerId
            createdAt: new Date(),
            updatedAt: new Date()
        };
        users.push(newUser);
        res.status(201).json({
            message: 'User created successfully',
            user: newUser
        });
    }
    catch (error) {
        console.error('Error creating user:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};
exports.createUser = createUser;
const updateUser = (req, res) => {
    try {
        const id = parseInt(req.params.id);
        const { name, email, phone, address, avatar } = req.body;
        const ownerId = req.userId;
        // Cari user berdasarkan ID dan owner
        const userIndex = users.findIndex(u => u.id === id && u.ownerId === ownerId);
        if (userIndex === -1) {
            res.status(404).json({ error: 'User not found' });
            return;
        }
        // Check if email already exists (excluding current user, untuk owner yang sama)
        if (email) {
            const existingUser = users.find(u => u.email === email && u.id !== id && u.ownerId === ownerId);
            if (existingUser) {
                res.status(409).json({ error: 'Email already exists' });
                return;
            }
        }
        // Update user
        const updatedUser = {
            ...users[userIndex],
            name: name || users[userIndex].name,
            email: email || users[userIndex].email,
            phone: phone !== undefined ? phone : users[userIndex].phone,
            address: address !== undefined ? address : users[userIndex].address,
            avatar: avatar !== undefined ? avatar : users[userIndex].avatar,
            updatedAt: new Date()
        };
        users[userIndex] = updatedUser;
        res.json({
            message: 'User updated successfully',
            user: updatedUser
        });
    }
    catch (error) {
        res.status(500).json({ error: 'Internal server error' });
    }
};
exports.updateUser = updateUser;
const deleteUser = (req, res) => {
    try {
        const id = parseInt(req.params.id);
        const ownerId = req.userId;
        // Cari user berdasarkan ID dan owner
        const userIndex = users.findIndex(u => u.id === id && u.ownerId === ownerId);
        if (userIndex === -1) {
            res.status(404).json({ error: 'User not found' });
            return;
        }
        const deletedUser = users[userIndex];
        users.splice(userIndex, 1);
        res.json({
            message: 'User deleted successfully',
            user: deletedUser
        });
    }
    catch (error) {
        res.status(500).json({ error: 'Internal server error' });
    }
};
exports.deleteUser = deleteUser;
//# sourceMappingURL=userController.js.map