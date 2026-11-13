import '../models/saved_drawing.dart';

final List<SavedDrawing> savedDrawings = [];
int _nextDrawingId = 1;
int _nextDrawingNumber = 1;
int newDrawingId() => _nextDrawingId++;
int takeNextDrawingNumber() => _nextDrawingNumber++;

