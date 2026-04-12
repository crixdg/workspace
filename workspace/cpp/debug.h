#pragma once

#include <bits/stdc++.h>

namespace cp_debug {

using namespace std;

template <typename T>
concept DebugIterable = requires(T t) {
  begin(t);
  end(t);
};

namespace detail {

inline void emit(short t) { cerr << t; }
inline void emit(unsigned short t) { cerr << t; }
inline void emit(int t) { cerr << t; }
inline void emit(long t) { cerr << t; }
inline void emit(long long t) { cerr << t; }
inline void emit(unsigned int t) { cerr << t; }
inline void emit(unsigned long t) { cerr << t; }
inline void emit(unsigned long long t) { cerr << t; }
inline void emit(float t) { cerr << t; }
inline void emit(double t) { cerr << t; }
inline void emit(long double t) { cerr << t; }
inline void emit(char t) { cerr << '\'' << t << '\''; }
inline void emit(const char *t) { cerr << '\"' << t << '\"'; }
inline void emit(const string &t) { cerr << '\"' << t << '\"'; }
inline void emit(bool t) { cerr << (t ? "true" : "false"); }

inline string int128_to_string(__int128_t t);
inline void emit(__int128_t t) { cerr << int128_to_string(t); }

template <typename T> inline void emit(const T &t) { cerr << t; }

template <DebugIterable T>
void emit(const T &t) {
  int f = 0;
  cerr << '[';
  for (const auto &i : t) {
    cerr << (f++ ? ", " : ""), emit(i);
  }
  cerr << "]";
}

template <typename T, typename V>
void emit(const pair<T, V> &t) {
  cerr << '(';
  emit(t.first);
  cerr << ", ";
  emit(t.second);
  cerr << ')';
}

template <size_t I = 0, typename... Ts>
void emit_tuple_recursive(const tuple<Ts...> &t) {
  if constexpr (I < sizeof...(Ts)) {
    if constexpr (I > 0) {
      cerr << ", ";
    }
    emit(get<I>(t));
    emit_tuple_recursive<I + 1>(t);
  }
}

template <typename... Ts>
void emit(const tuple<Ts...> &t) {
  cerr << '(';
  emit_tuple_recursive(t);
  cerr << ')';
}

template <typename K, typename V>
void emit(const map<K, V> &t) {
  int f = 0;
  cerr << '{';
  for (const auto &[k, v] : t) {
    cerr << (f++ ? ", " : ""), emit(k), cerr << ": ", emit(v);
  }
  cerr << '}';
}

template <typename K, typename V>
void emit(const unordered_map<K, V> &t) {
  int f = 0;
  cerr << '{';
  for (const auto &[k, v] : t) {
    cerr << (f++ ? ", " : ""), emit(k), cerr << ": ", emit(v);
  }
  cerr << '}';
}

template <typename K, typename V>
void emit(const multimap<K, V> &t) {
  int f = 0;
  cerr << '{';
  for (const auto &[k, v] : t) {
    cerr << (f++ ? ", " : ""), emit(k), cerr << ": ", emit(v);
  }
  cerr << '}';
}

template <typename K, typename V>
void emit(const unordered_multimap<K, V> &t) {
  int f = 0;
  cerr << '{';
  for (const auto &[k, v] : t) {
    cerr << (f++ ? ", " : ""), emit(k), cerr << ": ", emit(v);
  }
  cerr << '}';
}

template <typename T>
void emit(const queue<T> &t) {
  int f = 0;
  cerr << '[';
  queue<T> tmp = t;
  while (!tmp.empty()) {
    cerr << (f++ ? ", " : ""), emit(tmp.front()), tmp.pop();
  }
  cerr << "]";
}

template <typename T>
void emit(const stack<T> &t) {
  int f = 0;
  cerr << '[';
  stack<T> tmp = t;
  while (!tmp.empty()) {
    cerr << (f++ ? ", " : ""), emit(tmp.top()), tmp.pop();
  }
  cerr << "]";
}

template <typename T>
void emit(const priority_queue<T> &t) {
  int f = 0;
  cerr << '[';
  priority_queue<T> tmp = t;
  while (!tmp.empty()) {
    cerr << (f++ ? ", " : ""), emit(tmp.top()), tmp.pop();
  }
  cerr << "]";
}

template <typename T>
void emit(const priority_queue<T, vector<T>, greater<T>> &t) {
  int f = 0;
  cerr << '[';
  priority_queue<T, vector<T>, greater<T>> tmp = t;
  while (!tmp.empty()) {
    cerr << (f++ ? ", " : ""), emit(tmp.top()), tmp.pop();
  }
  cerr << "]";
}

inline string int128_to_string(__int128_t t) {
  if (t == 0) {
    return "0";
  }

  bool neg = t < 0;
  if (t < 0) {
    t = -t;
  }

  string s;
  while (t) {
    s.push_back(static_cast<char>(t % 10 + '0'));
    t /= 10;
  }
  if (neg) {
    s.push_back('-');
  }
  reverse(s.begin(), s.end());
  return s;
}

inline void emit_args() { cerr << '\n'; }

template <typename T, typename... V>
inline void emit_args(T t, V... v) {
  emit(t);
  if (sizeof...(v)) {
    cerr << ", ";
  }
  emit_args(v...);
}

} // namespace detail

} // namespace cp_debug

#define debug(t...)                                         \
  cerr << "\e[90m" << __func__ << "::" << __LINE__ << ": "; \
  ::cp_debug::detail::emit_args(t);                         \
  cerr << "\e[39m";
