// Copyright (c) 2026-present, FromCero. All rights reserved.

#pragma once

#include <bits/stdc++.h>
using namespace std;

template <typename T> void __info(const T &t);

template <typename T, typename V> void __info(const pair<T, V> &t);
template <typename T, typename V, typename K> void __info(const tuple<T, V, K> &t);

template <typename T> void __info(const stack<T> &t);
template <typename T> void __info(const queue<T> &t);

template <typename T> void __info(const priority_queue<T> &t);
template <typename T> void __info(const priority_queue<T, vector<T>, greater<T>> &t);

inline void __info(short t) { cerr << t; }
inline void __info(unsigned short t) { cerr << t; }
inline void __info(int t) { cerr << t; }
inline void __info(long t) { cerr << t; }
inline void __info(long long t) { cerr << t; }
inline void __info(unsigned int t) { cerr << t; }
inline void __info(unsigned long t) { cerr << t; }
inline void __info(unsigned long long t) { cerr << t; }
inline void __info(float t) { cerr << t; }
inline void __info(double t) { cerr << t; }
inline void __info(long double t) { cerr << t; }
inline void __info(char t) { cerr << '\'' << t << '\''; }
inline void __info(const char *t) { cerr << '\"' << t << '\"'; }
inline void __info(const string &t) { cerr << '\"' << t << '\"'; }
inline void __info(bool t) { cerr << (t ? "true" : "false"); }

inline string to_string(__int128_t t);
inline void __info(__int128_t t) { cerr << to_string(t); }

inline void __print() { cerr << '\n'; }

template <typename T, typename... V> inline void __print(T t, V... v) {
  __info(t);
  if (sizeof...(v)) {
    cerr << ", ";
  }
  __print(v...);
}

#define debug(t...)                                                                                                                                  \
  cerr << "\e[90m" << __func__ << "::" << __LINE__ << ": ";                                                                                          \
  __print(t);                                                                                                                                        \
  cerr << "\e[39m";

inline void __test__() {
  short sh = SHRT_MAX;
  debug(sh);
  unsigned short ush = USHRT_MAX;
  debug(ush);

  int i = INT_MAX;
  debug(i);
  long l = LONG_MAX;
  debug(l);
  long long ll = LLONG_MAX;
  debug(ll);
  __int128_t i128 = LLONG_MAX;
  debug(i128);

  unsigned int ui = UINT_MAX;
  debug(ui);
  unsigned long ul = ULONG_MAX;
  debug(ul);
  unsigned long long ull = ULLONG_MAX;
  debug(ull);

  float f = FLT_MAX;
  debug(f);
  double d = DBL_MAX;
  debug(d);
  long double ld = LDBL_MAX;
  debug(ld);

  char c = 'a';
  debug(c);
  const char *cs = "hello";
  debug(cs);
  string s = "hello world";
  debug(s);

  bool b = true;
  debug(b);

  pair<int, int> p = {1, 2};
  debug(p);
  tuple<int, int, int> tpl = {1, 2, 3};
  debug(tpl);

  vector<int> v = {1, 2, 3};
  debug(v);
  array<int, 3> a = {1, 2, 3};
  debug(a);

  deque<int> dq = {1, 2, 3};
  debug(dq);
  list<int> lt = {1, 2, 3};
  debug(lt);

  stack<int> stk;
  stk.push(1);
  stk.push(2);
  stk.push(3);
  debug(stk);

  queue<int> qu;
  qu.push(1);
  qu.push(2);
  qu.push(3);
  debug(qu);

  unordered_set<int> us = {1, 2, 3};
  set<int> st = {1, 2, 3};
  multiset<int> ms = {1, 2, 3};
  debug(us, st, ms);

  map<int, int> m = {{1, 2}, {3, 4}};
  unordered_map<int, int> um = {{1, 2}, {3, 4}};
  multimap<int, int> mm = {{1, 2}, {3, 4}};
  debug(m, um, mm);

  priority_queue<int> max_heap;
  max_heap.push(1);
  max_heap.push(2);
  max_heap.push(3);
  debug(max_heap);

  priority_queue<int, vector<int>, greater<int>> min_heap;
  min_heap.push(1);
  min_heap.push(2);
  min_heap.push(3);
  debug(min_heap);
}

template <typename T> void __info(const T &t) {
  int f = 0;
  cerr << '[';
  for (auto &i : t) {
    cerr << (f++ ? ", " : ""), __info(i);
  }
  cerr << "]";
}

template <typename T> void __info(const queue<T> &t) {
  int f = 0;
  cerr << '[';
  queue<T> tmp = t;
  while (!tmp.empty()) {
    cerr << (f++ ? ", " : ""), __info(tmp.front()), tmp.pop();
  }
  cerr << "]";
}

template <typename T> void __info(const stack<T> &t) {
  int f = 0;
  cerr << '[';
  stack<T> tmp = t;
  while (!tmp.empty()) {
    cerr << (f++ ? ", " : ""), __info(tmp.top()), tmp.pop();
  }
  cerr << "]";
}

template <typename T> void __info(const priority_queue<T> &t) {
  int f = 0;
  cerr << '[';
  priority_queue<T> tmp = t;
  while (!tmp.empty()) {
    cerr << (f++ ? ", " : ""), __info(tmp.top()), tmp.pop();
  }
  cerr << "]";
}

template <typename T> void __info(const priority_queue<T, vector<T>, greater<T>> &t) {
  int f = 0;
  cerr << '[';
  priority_queue<T, vector<T>, greater<T>> tmp = t;
  while (!tmp.empty()) {
    cerr << (f++ ? ", " : ""), __info(tmp.top()), tmp.pop();
  }
  cerr << "]";
}

template <typename T, typename V> void __info(const pair<T, V> &t) {
  cerr << '(';
  __info(t.first);
  cerr << ", ";
  __info(t.second);
  cerr << ')';
}

template <typename T, typename V, typename K> void __info(const tuple<T, V, K> &t) {
  cerr << '(';
  __info(get<0>(t));
  cerr << ", ";
  __info(get<1>(t));
  cerr << ", ";
  __info(get<2>(t));
  cerr << ')';
}

inline string to_string(__int128_t t) {
  if (t == 0) {
    return "0";
  }

  bool neg = t < 0;
  if (t < 0) {
    t = -t;
  }

  string s;
  while (t) {
    s.push_back(t % 10 + '0');
    t /= 10;
  }
  if (neg) {
    s.push_back('-');
  }
  reverse(s.begin(), s.end());
  return s;
}
