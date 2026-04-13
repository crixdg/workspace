#pragma once

#include <bits/stdc++.h>

namespace lc_prelude {

using namespace std;

// -- Leetcode-shaped DS (local run only) ------------------------------------

template <typename T>
struct LinkedListNode {
  T val;
  LinkedListNode *next;
  LinkedListNode(T x) : val(x), next(nullptr) {}
};

template <typename T>
struct BinaryTreeNode {
  T val;
  BinaryTreeNode *left, *right;
  BinaryTreeNode(T x) : val(x), left(nullptr), right(nullptr) {}
};

namespace detail {

// -- Parsers ----------------------------------------------------------------

template <typename T> T input_parse(const string &s);

template <> inline int input_parse<int>(const string &s) { return stoi(s); }
template <> inline long long input_parse<long long>(const string &s) { return stoll(s); }
template <> inline double input_parse<double>(const string &s) { return stod(s); }
template <> inline bool input_parse<bool>(const string &s) { return s == "true"; }
template <> inline char input_parse<char>(const string &s) { return s[1]; }
template <> inline string input_parse<string>(const string &s) { return s.substr(1, s.size() - 2); }

inline vector<string> split_bracket(const string &s) {
  int depth = 0;
  vector<string> tokens;
  string cur;
  for (char c : s.substr(1, s.size() - 2)) {
    if (c == '[') {
      depth++;
      cur += c;
    } else if (c == ']') {
      depth--;
      cur += c;
    } else if (c == ',' && depth == 0) {
      tokens.push_back(cur);
      cur.clear();
    } else {
      cur += c;
    }
  }
  if (!cur.empty()) { tokens.push_back(cur); }
  return tokens;
}

template <typename T>
vector<T> input_parse_vector(const string &s) {
  vector<T> res;
  for (const string &tok : split_bracket(s)) {
    res.push_back(input_parse<T>(tok));
  }
  return res;
}

template <> inline vector<int> input_parse<vector<int>>(const string &s) { return input_parse_vector<int>(s); }
template <> inline vector<long long> input_parse<vector<long long>>(const string &s) { return input_parse_vector<long long>(s); }
template <> inline vector<double> input_parse<vector<double>>(const string &s) { return input_parse_vector<double>(s); }
template <> inline vector<bool> input_parse<vector<bool>>(const string &s) { return input_parse_vector<bool>(s); }
template <> inline vector<char> input_parse<vector<char>>(const string &s) { return input_parse_vector<char>(s); }
template <> inline vector<string> input_parse<vector<string>>(const string &s) { return input_parse_vector<string>(s); }

template <> inline vector<vector<int>> input_parse<vector<vector<int>>>(const string &s) { return input_parse_vector<vector<int>>(s); }
template <> inline vector<vector<long long>> input_parse<vector<vector<long long>>>(const string &s) { return input_parse_vector<vector<long long>>(s); }
template <> inline vector<vector<double>> input_parse<vector<vector<double>>>(const string &s) { return input_parse_vector<vector<double>>(s); }
template <> inline vector<vector<bool>> input_parse<vector<vector<bool>>>(const string &s) { return input_parse_vector<vector<bool>>(s); }
template <> inline vector<vector<char>> input_parse<vector<vector<char>>>(const string &s) { return input_parse_vector<vector<char>>(s); }
template <> inline vector<vector<string>> input_parse<vector<vector<string>>>(const string &s) { return input_parse_vector<vector<string>>(s); }

template <> inline vector<vector<vector<int>>> input_parse<vector<vector<vector<int>>>>(const string &s) { return input_parse_vector<vector<vector<int>>>(s); }
template <> inline vector<vector<vector<long long>>> input_parse<vector<vector<vector<long long>>>>(const string &s) { return input_parse_vector<vector<vector<long long>>>(s); }
template <> inline vector<vector<vector<double>>> input_parse<vector<vector<vector<double>>>>(const string &s) { return input_parse_vector<vector<vector<double>>>(s); }
template <> inline vector<vector<vector<bool>>> input_parse<vector<vector<vector<bool>>>>(const string &s) { return input_parse_vector<vector<vector<bool>>>(s); }
template <> inline vector<vector<vector<char>>> input_parse<vector<vector<vector<char>>>>(const string &s) { return input_parse_vector<vector<vector<char>>>(s); }
template <> inline vector<vector<vector<string>>> input_parse<vector<vector<vector<string>>>>(const string &s) { return input_parse_vector<vector<vector<string>>>(s); }

// -- Linked list / tree from bracket lines -----------------------------------

template <typename T>
LinkedListNode<T> *input_parse_linked_list(const string &s) {
  vector<string> tokens = split_bracket(s);
  if (tokens.empty()) { return nullptr; }

  LinkedListNode<T> dummy(T{});
  LinkedListNode<T> *cur = &dummy;
  for (const string &tok : tokens) {
    cur->next = new LinkedListNode<T>(input_parse<T>(tok));
    cur = cur->next;
  }
  return dummy.next;
}

template <> inline LinkedListNode<int> *input_parse<LinkedListNode<int> *>(const string &s) { return input_parse_linked_list<int>(s); }
template <> inline LinkedListNode<long long> *input_parse<LinkedListNode<long long> *>(const string &s) { return input_parse_linked_list<long long>(s); }
template <> inline LinkedListNode<double> *input_parse<LinkedListNode<double> *>(const string &s) { return input_parse_linked_list<double>(s); }
template <> inline LinkedListNode<bool> *input_parse<LinkedListNode<bool> *>(const string &s) { return input_parse_linked_list<bool>(s); }
template <> inline LinkedListNode<char> *input_parse<LinkedListNode<char> *>(const string &s) { return input_parse_linked_list<char>(s); }
template <> inline LinkedListNode<string> *input_parse<LinkedListNode<string> *>(const string &s) { return input_parse_linked_list<string>(s); }

template <typename T>
BinaryTreeNode<T> *input_parse_binary_tree(const string &s) {
  vector<string> tokens = split_bracket(s);
  if (tokens.empty() || tokens[0] == "null") { return nullptr; }

  BinaryTreeNode<T> *root = new BinaryTreeNode<T>(input_parse<T>(tokens[0]));
  queue<BinaryTreeNode<T> *> q;
  q.push(root);

  int i = 1;
  while (!q.empty() && i < (int)tokens.size()) {
    BinaryTreeNode<T> *node = q.front();
    q.pop();

    if (i < (int)tokens.size() && tokens[i] != "null") {
      node->left = new BinaryTreeNode<T>(input_parse<T>(tokens[i]));
      q.push(node->left);
    }
    i++;
    if (i < (int)tokens.size() && tokens[i] != "null") {
      node->right = new BinaryTreeNode<T>(input_parse<T>(tokens[i]));
      q.push(node->right);
    }
    i++;
  }
  return root;
}

template <> inline BinaryTreeNode<int> *input_parse<BinaryTreeNode<int> *>(const string &s) { return input_parse_binary_tree<int>(s); }
template <> inline BinaryTreeNode<long long> *input_parse<BinaryTreeNode<long long> *>(const string &s) { return input_parse_binary_tree<long long>(s); }
template <> inline BinaryTreeNode<double> *input_parse<BinaryTreeNode<double> *>(const string &s) { return input_parse_binary_tree<double>(s); }
template <> inline BinaryTreeNode<bool> *input_parse<BinaryTreeNode<bool> *>(const string &s) { return input_parse_binary_tree<bool>(s); }
template <> inline BinaryTreeNode<char> *input_parse<BinaryTreeNode<char> *>(const string &s) { return input_parse_binary_tree<char>(s); }
template <> inline BinaryTreeNode<string> *input_parse<BinaryTreeNode<string> *>(const string &s) { return input_parse_binary_tree<string>(s); }

// -- stdin -------------------------------------------------------------------

template <typename T> T input_read() {
  string line;
  while (line.empty()) {
    if (!getline(cin, line)) {
      cerr << "error: not enough input for parameters\n";
      exit(1);
    }
    auto l = line.find_first_not_of(" \t\r");
    auto r = line.find_last_not_of(" \t\r");
    line = (l == string::npos) ? "" : line.substr(l, r - l + 1);
  }
  return input_parse<T>(line);
}

template <typename Tuple, size_t... I>
Tuple input_read_params(index_sequence<I...>) {
  return Tuple{input_read<tuple_element_t<I, Tuple>>()...};
}

template <typename Tuple>
Tuple input_read_params() {
  return input_read_params<Tuple>(make_index_sequence<tuple_size_v<Tuple>>{});
}

// -- stdout ------------------------------------------------------------------

inline void output_print(const int &v) { cout << v; }
inline void output_print(const long long &v) { cout << v; }
inline void output_print(const double &v) { cout << fixed << setprecision(15) << v; }
inline void output_print(const bool &v) { cout << (v ? "true" : "false"); }
inline void output_print(const string &v) { cout << '"' << v << '"'; }
inline void output_print(const char &v) { cout << '\'' << v << '\''; }

template <typename T>
void output_print(const vector<T> &v) {
  cout << '[';
  for (int i = 0; i < (int)v.size(); i++) {
    if (i) { cout << ','; }
    output_print(v[i]);
  }
  cout << ']';
}

template <typename T>
void output_print(const LinkedListNode<T> *head) {
  cout << '[';
  bool first = true;
  while (head) {
    if (!first) { cout << ','; }
    output_print(head->val);
    first = false;
    head = head->next;
  }
  cout << ']';
}

template <typename T>
void output_print(const BinaryTreeNode<T> *root) {
  if (!root) {
    cout << "null";
    return;
  }
  vector<optional<T>> vals;
  queue<const BinaryTreeNode<T> *> q;
  q.push(root);
  while (!q.empty()) {
    const BinaryTreeNode<T> *node = q.front();
    q.pop();
    if (!node) {
      vals.push_back(nullopt);
    } else {
      vals.push_back(node->val);
      q.push(node->left);
      q.push(node->right);
    }
  }
  while (!vals.empty() && !vals.back().has_value()) { vals.pop_back(); }
  cout << '[';
  for (int i = 0; i < (int)vals.size(); i++) {
    if (i) { cout << ','; }
    if (!vals[i].has_value()) {
      cout << "null";
    } else {
      output_print(*vals[i]);
    }
  }
  cout << ']';
}

template <typename T> struct MethodTraits;
template <typename R, typename C, typename... Args>
struct MethodTraits<R (C::*)(Args...)> {
  using return_type = R;
  using class_type = C;
  using param_types = tuple<decay_t<Args>...>;
  static constexpr size_t arity = sizeof...(Args);
};

} // namespace detail

// -- Run Solution::method from stdin / print result -------------------------

template <auto MethodPtr, typename Sol>
void dispatch(Sol *sol) {
  using Traits = detail::MethodTraits<decltype(MethodPtr)>;
  using Params = typename Traits::param_types;
  using Ret = typename Traits::return_type;

  auto args = detail::input_read_params<Params>();

  if constexpr (is_void_v<Ret>) {
    apply([&](auto &...a) { (sol->*MethodPtr)(a...); }, args);
  } else {
    auto result = apply([&](auto &...a) { return (sol->*MethodPtr)(a...); }, args);
    detail::output_print(result);
    cout << '\n';
  }
}

} // namespace lc_prelude
