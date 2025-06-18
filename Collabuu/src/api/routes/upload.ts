import express, { Request, Response } from 'express';
import { supabase } from '../../config/supabase';
import { authenticateToken } from '../../middleware/auth';
import multer from 'multer';
import { v4 as uuidv4 } from 'uuid';

// Configure multer for memory storage
const upload = multer({ 
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req: any, file: any, cb: any) => {
    // Allow only image files
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'));
    }
  }
});

export class UploadRouter {
  public router = express.Router();

  constructor() {
    this.router.post('/image', authenticateToken, upload.single('image'), this.uploadImage.bind(this));
    this.router.delete('/:fileId', authenticateToken, this.deleteFile.bind(this));
  }

  private async uploadImage(req: Request & { file?: Express.Multer.File }, res: Response) {
    try {
      if (!req.file) {
        return res.status(400).json({ error: 'No image file provided' });
      }

      const userId = (req as any).user.id;
      const file = req.file;
      const fileExtension = file.originalname.split('.').pop();
      const fileName = `${userId}/${uuidv4()}.${fileExtension}`;

      // Upload to Supabase Storage
      const { data, error } = await supabase.storage
        .from('uploads')
        .upload(fileName, file.buffer, {
          contentType: file.mimetype,
          upsert: false
        });

      if (error) {
        console.error('Upload error:', error);
        return res.status(500).json({ error: 'Failed to upload image' });
      }

      // Get public URL
      const { data: publicUrlData } = supabase.storage
        .from('uploads')
        .getPublicUrl(fileName);

      // Store file metadata in database
      const { data: fileRecord, error: dbError } = await supabase
        .from('uploaded_files')
        .insert([{
          id: uuidv4(),
          user_id: userId,
          file_name: file.originalname,
          file_path: fileName,
          file_size: file.size,
          mime_type: file.mimetype,
          public_url: publicUrlData.publicUrl
        }])
        .select()
        .single();

      if (dbError) {
        console.error('Database error:', dbError);
        // Try to clean up uploaded file
        await supabase.storage.from('uploads').remove([fileName]);
        return res.status(500).json({ error: 'Failed to save file metadata' });
      }

      res.status(200).json({ 
        fileId: fileRecord.id,
        fileName: file.originalname,
        fileUrl: publicUrlData.publicUrl,
        fileSize: file.size,
        mimeType: file.mimetype
      });
    } catch (error) {
      console.error('Upload image error:', error);
      res.status(500).json({ error: 'Failed to upload image' });
    }
  }

  private async deleteFile(req: Request, res: Response) {
    try {
      const { fileId } = req.params;
      const userId = (req as any).user.id;
      
      if (!fileId) {
        return res.status(400).json({ error: 'File ID is required' });
      }

      // Get file record from database
      const { data: fileRecord, error: fetchError } = await supabase
        .from('uploaded_files')
        .select('*')
        .eq('id', fileId)
        .eq('user_id', userId) // Ensure user can only delete their own files
        .single();

      if (fetchError || !fileRecord) {
        return res.status(404).json({ error: 'File not found or access denied' });
      }

      // Delete from storage
      const { error: storageError } = await supabase.storage
        .from('uploads')
        .remove([fileRecord.file_path]);

      if (storageError) {
        console.error('Storage deletion error:', storageError);
        return res.status(500).json({ error: 'Failed to delete file from storage' });
      }

      // Delete from database
      const { error: dbError } = await supabase
        .from('uploaded_files')
        .delete()
        .eq('id', fileId);

      if (dbError) {
        console.error('Database deletion error:', dbError);
        return res.status(500).json({ error: 'Failed to delete file record' });
      }

      res.status(200).json({ message: 'File deleted successfully' });
    } catch (error) {
      console.error('Delete file error:', error);
      res.status(500).json({ error: 'Failed to delete file' });
    }
  }
} 