import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/user.dart';

class UserDetailScreen extends StatelessWidget {
  final User user;

  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Detail',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: user.avatar != null && user.avatar!.isNotEmpty
                        ? Colors.grey[400]
                        : Colors.grey[500], // Warna abu-abu konsisten dengan desain
                    child: user.avatar != null && user.avatar!.isNotEmpty
                        ? ClipOval(
                            child: _buildAvatarImage(user.avatar!, 120),
                          )
                        : Text(
                            user.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w600, // Konsisten dengan edit profile
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Information Cards
            _buildInfoCard(
              icon: Icons.person,
              title: 'Full Name',
              content: user.name,
            ),
            const SizedBox(height: 16),
            
            _buildInfoCard(
              icon: Icons.email,
              title: 'Email Address',
              content: user.email,
            ),
            const SizedBox(height: 16),
            
            if (user.phone != null && user.phone!.isNotEmpty)
              _buildInfoCard(
                icon: Icons.phone,
                title: 'Phone Number',
                content: user.phone!,
              ),
            if (user.phone != null && user.phone!.isNotEmpty)
              const SizedBox(height: 16),
            
            if (user.address != null && user.address!.isNotEmpty)
              _buildInfoCard(
                icon: Icons.location_on,
                title: 'Address',
                content: user.address!,
              ),
            if (user.address != null && user.address!.isNotEmpty)
              const SizedBox(height: 16),
            
            _buildInfoCard(
              icon: Icons.calendar_today,
              title: 'Created At',
              content: _formatDateTime(user.createdAt),
            ),
            const SizedBox(height: 16),
            
            _buildInfoCard(
              icon: Icons.update,
              title: 'Last Updated',
              content: _formatDateTime(user.updatedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Colors.blue,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarImage(String avatar, double size) {
    // Cek apakah avatar adalah URL atau base64
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      // Avatar adalah URL
      return Image.network(
        avatar,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.blue.withOpacity(0.1),
            child: Icon(
              Icons.person,
              size: size * 0.6,
              color: Colors.blue,
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: SizedBox(
                width: size * 0.5,
                height: size * 0.5,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / 
                        loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
      );
    } else {
      // Avatar adalah base64
      try {
        return Image.memory(
          base64Decode(avatar),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.blue.withOpacity(0.1),
              child: Icon(
                Icons.person,
                size: size * 0.6,
                color: Colors.blue,
              ),
            );
          },
        );
      } catch (e) {
        return Container(
          color: Colors.blue.withOpacity(0.1),
          child: Icon(
            Icons.person,
            size: size * 0.6,
            color: Colors.blue,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}