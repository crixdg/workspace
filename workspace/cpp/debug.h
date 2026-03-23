#pragma once

#include <bits/stdc++.h>

using namespace std;

template <typename T>
void __dbg(const T &t);

template <typename T, typename V>
void __dbg(const pair<T, V> &t);
template <typename... Ts>
void __dbg(const tuple<Ts...> &t);

template <typename K, typename V>
void __dbg(const map<K, V> &t);
template <typename K, typename V>
void __dbg(const unordered_map<K, V> &t);
template <typename K, typename V>
void __dbg(const multimap<K, V> &t);
template <typename K, typename V>
void __dbg(const unordered_multimap<K, V> &t);

template <typename T>
void __dbg(const stack<T> &t);
template <typename T>
void __dbg(const queue<T> &t);

template <typename T>
void __dbg(const priority_queue<T> &t);
template <typename T>
void __dbg(const priority_queue<T, vector<T>, greater<T>> &t);

inline void __dbg(short t) { cerr << t; }
inline void __dbg(unsigned short t) { cerr << t; }
inline void __dbg(int t) { cerr << t; }
inline void __dbg(long t) { cerr << t; }
inline void __dbg(long long t) { cerr << t; }
inline void __dbg(unsigned int t) { cerr << t; }
inline void __dbg(unsigned long t) { cerr << t; }
inline void __dbg(unsigned long long t) { cerr << t; }
inline void __dbg(float t) { cerr << t; }
inline void __dbg(double t) { cerr << t; }
inline void __dbg(long double t) { cerr << t; }
inline void __dbg(char t) { cerr << '\'' << t << '\''; }
inline void __dbg(const char *t) { cerr << '\"' << t << '\"'; }
inline void __dbg(const string &t) { cerr << '\"' << t << '\"'; }
inline void __dbg(bool t) { cerr << (t ? "true" : "false"); }

inline string __i128_to_string(__int128_t t);
inline void __dbg(__int128_t t) { cerr << __i128_to_string(t); }

inline void __dbg_print() { cerr << '\n'; }

template <typename T, typename... V>
inline void __dbg_print(T t, V... v) {
  __dbg(t);
  if (sizeof...(v)) {
    cerr << ", ";
  }
  __dbg_print(v...);
}

#define debug(t...)                                                                                                                                  \
  cerr << "\e[90m" << __func__ << "::" << __LINE__ << ": ";                                                                                          \
  __dbg_print(t);                                                                                                                                    \
  cerr << "\e[39m";

template <typename T>
void __dbg(const T &t) {
  int f = 0;
  cerr << '[';
  for (auto &i : t) {
    cerr << (f++ ? ", " : ""), __dbg(i);
  }
  cerr << "]";
}

template <typename T, typename V>
void __dbg(const pair<T, V> &t) {
  cerr << '(';
  __dbg(t.first);
  cerr << ", ";
  __dbg(t.second);
  cerr << ')';
}

template <size_t I = 0, typename... Ts>
void _dbg_tuple(const tuple<Ts...> &t) {
  if constexpr (I < sizeof...(Ts)) {
    if constexpr (I > 0) {
      cerr << ", ";
    }
    __dbg(get<I>(t));
    _dbg_tuple<I + 1>(t);
  }
}

template <typename... Ts>
void __dbg(const tuple<Ts...> &t) {
  cerr << '(';
  _dbg_tuple(t);
  cerr << ')';
}

template <typename K, typename V>
void __dbg(const map<K, V> &t) {
  int f = 0;
  cerr << '{';
  for (auto &[k, v] : t) {
    cerr << (f++ ? ", " : ""), __dbg(k), cerr << ": ", __dbg(v);
  }
  cerr << '}';
}

template <typename K, typename V>
void __dbg(const unordered_map<K, V> &t) {
  int f = 0;
  cerr << '{';
  for (auto &[k, v] : t) {
    cerr << (f++ ? ", " : ""), __dbg(k), cerr << ": ", __dbg(v);
  }
  cerr << '}';
}

template <typename K, typename V>
void __dbg(const multimap<K, V> &t) {
  int f = 0;
  cerr << '{';
  for (auto &[k, v] : t) {
    cerr << (f++ ? ", " : ""), __dbg(k), cerr << ": ", __dbg(v);
  }
  cerr << '}';
}

template <typename K, typename V>
void __dbg(const unordered_multimap<K, V> &t) {
  int f = 0;
  cerr << '{';
  for (auto &[k, v] : t) {
    cerr << (f++ ? ", " : ""), __dbg(k), cerr << ": ", __dbg(v);
  }
  cerr << '}';
}

template <typename T>
void __dbg(const queue<T> &t) {
  int f = 0;
  cerr << '[';
  queue<T> tmp = t;
  while (!tmp.empty()) {
    cerr << (f++ ? ", " : ""), __dbg(tmp.front()), tmp.pop();
  }
  cerr << "]";
}

template <typename T>
void __dbg(const stack<T> &t) {
  int f = 0;
  cerr << '[';
  stack<T> tmp = t;
  while (!tmp.empty()) {
    cerr << (f++ ? ", " : ""), __dbg(tmp.top()), tmp.pop();
  }
  cerr << "]";
}

template <typename T>
void __dbg(const priority_queue<T> &t) {
  int f = 0;
  cerr << '[';
  priority_queue<T> tmp = t;
  while (!tmp.empty()) {
    cerr << (f++ ? ", " : ""), __dbg(tmp.top()), tmp.pop();
  }
  cerr << "]";
}

template <typename T>
void __dbg(const priority_queue<T, vector<T>, greater<T>> &t) {
  int f = 0;
  cerr << '[';
  priority_queue<T, vector<T>, greater<T>> tmp = t;
  while (!tmp.empty()) {
    cerr << (f++ ? ", " : ""), __dbg(tmp.top()), tmp.pop();
  }
  cerr << "]";
}

inline string __i128_to_string(__int128_t t) {
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
