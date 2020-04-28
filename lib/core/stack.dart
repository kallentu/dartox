import 'dart:collection';

class Stack<T> {
  final ListQueue<T> _list = ListQueue();

  bool get isEmpty => _list.isEmpty;

  bool get isNotEmpty => _list.isNotEmpty;

  void push(T e) => _list.addLast(e);

  T pop() {
    T res = _list.last;
    _list.removeLast();
    return res;
  }

  T peek() => _list.last;

  int size() => _list.length;

  T get(int index) => _list.elementAt(index);
}
