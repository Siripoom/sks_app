import 'package:sks/data/mock_data.dart';
import 'package:sks/models/child.dart';

abstract class IChildService {
  Future<List<Child>> getChildrenByParentId(String parentId);
  Future<Child?> getChildById(String childId);
  Future<bool> addChild(Child child);
  Future<bool> updateChild(Child child);
  Future<bool> deleteChild(String childId);
}

class MockChildService implements IChildService {
  final List<Child> _children = List.from(MockData.children);

  @override
  Future<List<Child>> getChildrenByParentId(String parentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _children.where((c) => c.parentId == parentId).toList();
  }

  @override
  Future<Child?> getChildById(String childId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _children.firstWhere((c) => c.id == childId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> addChild(Child child) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _children.add(child);
    return true;
  }

  @override
  Future<bool> updateChild(Child child) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _children.indexWhere((c) => c.id == child.id);
    if (index != -1) {
      _children[index] = child;
      return true;
    }
    return false;
  }

  @override
  Future<bool> deleteChild(String childId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _children.removeWhere((c) => c.id == childId);
    return true;
  }

  List<Child> getChildren() => _children;
}
