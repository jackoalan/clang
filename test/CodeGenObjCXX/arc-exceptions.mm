// RUN: %clang_cc1 -triple x86_64-apple-darwin10 -emit-llvm -fobjc-arc -fexceptions -fobjc-exceptions -fcxx-exceptions -fobjc-runtime-has-weak -o - -fobjc-arc-exceptions %s | FileCheck %s

@class Ety;

// These first four tests are all PR11732 / rdar://problem/10667070.

void test0_helper(void);
void test0(void) {
  @try {
    test0_helper();
  } @catch (Ety *e) {
  }
}
// CHECK: define void @_Z5test0v()
// CHECK:      [[E:%.*]] = alloca [[ETY:%.*]]*, align 8
// CHECK-NEXT: invoke void @_Z12test0_helperv()
// CHECK:      [[T0:%.*]] = call i8* @objc_begin_catch(
// CHECK-NEXT: [[T1:%.*]] = bitcast i8* [[T0]] to [[ETY]]*
// CHECK-NEXT: [[T2:%.*]] = bitcast [[ETY]]* [[T1]] to i8*
// CHECK-NEXT: [[T3:%.*]] = call i8* @objc_retain(i8* [[T2]]) [[NUW:#[0-9]+]]
// CHECK-NEXT: [[T4:%.*]] = bitcast i8* [[T3]] to [[ETY]]*
// CHECK-NEXT: store [[ETY]]* [[T4]], [[ETY]]** [[E]]
// CHECK-NEXT: [[T0:%.*]] = bitcast [[ETY]]** [[E]] to i8**
// CHECK-NEXT: call void @objc_storeStrong(i8** [[T0]], i8* null) [[NUW]]
// CHECK-NEXT: call void @objc_end_catch() [[NUW]]

void test1_helper(void);
void test1(void) {
  @try {
    test1_helper();
  } @catch (__weak Ety *e) {
  }
}
// CHECK: define void @_Z5test1v()
// CHECK:      [[E:%.*]] = alloca [[ETY:%.*]]*, align 8
// CHECK-NEXT: invoke void @_Z12test1_helperv()
// CHECK:      [[T0:%.*]] = call i8* @objc_begin_catch(
// CHECK-NEXT: [[T1:%.*]] = bitcast i8* [[T0]] to [[ETY]]*
// CHECK-NEXT: [[T2:%.*]] = bitcast [[ETY]]** [[E]] to i8**
// CHECK-NEXT: [[T3:%.*]] = bitcast [[ETY]]* [[T1]] to i8*
// CHECK-NEXT: call i8* @objc_initWeak(i8** [[T2]], i8* [[T3]]) [[NUW]]
// CHECK-NEXT: [[T0:%.*]] = bitcast [[ETY]]** [[E]] to i8**
// CHECK-NEXT: call void @objc_destroyWeak(i8** [[T0]]) [[NUW]]
// CHECK-NEXT: call void @objc_end_catch() [[NUW]]

void test2_helper(void);
void test2(void) {
  try {
    test2_helper();
  } catch (Ety *e) {
  }
}
// CHECK: define void @_Z5test2v()
// CHECK:      [[E:%.*]] = alloca [[ETY:%.*]]*, align 8
// CHECK-NEXT: invoke void @_Z12test2_helperv()
// CHECK:      [[T0:%.*]] = call i8* @__cxa_begin_catch(
// CHECK-NEXT: [[T1:%.*]] = bitcast i8* [[T0]] to [[ETY]]*
// CHECK-NEXT: [[T2:%.*]] = bitcast [[ETY]]* [[T1]] to i8*
// CHECK-NEXT: [[T3:%.*]] = call i8* @objc_retain(i8* [[T2]]) [[NUW]]
// CHECK-NEXT: [[T4:%.*]] = bitcast i8* [[T3]] to [[ETY]]*
// CHECK-NEXT: store [[ETY]]* [[T4]], [[ETY]]** [[E]]
// CHECK-NEXT: [[T0:%.*]] = bitcast [[ETY]]** [[E]] to i8**
// CHECK-NEXT: call void @objc_storeStrong(i8** [[T0]], i8* null) [[NUW]]
// CHECK-NEXT: call void @__cxa_end_catch() [[NUW]]

void test3_helper(void);
void test3(void) {
  try {
    test3_helper();
  } catch (Ety * __weak e) {
  }
}
// CHECK: define void @_Z5test3v()
// CHECK:      [[E:%.*]] = alloca [[ETY:%.*]]*, align 8
// CHECK-NEXT: invoke void @_Z12test3_helperv()
// CHECK:      [[T0:%.*]] = call i8* @__cxa_begin_catch(
// CHECK-NEXT: [[T1:%.*]] = bitcast i8* [[T0]] to [[ETY]]*
// CHECK-NEXT: [[T2:%.*]] = bitcast [[ETY]]** [[E]] to i8**
// CHECK-NEXT: [[T3:%.*]] = bitcast [[ETY]]* [[T1]] to i8*
// CHECK-NEXT: call i8* @objc_initWeak(i8** [[T2]], i8* [[T3]]) [[NUW]]
// CHECK-NEXT: [[T0:%.*]] = bitcast [[ETY]]** [[E]] to i8**
// CHECK-NEXT: call void @objc_destroyWeak(i8** [[T0]]) [[NUW]]
// CHECK-NEXT: call void @__cxa_end_catch() [[NUW]]

namespace test4 {
  struct A {
    id single;
    id array[2][3];

    A();
  };

  A::A() {
    throw 0;
  }
  // CHECK:    define void @_ZN5test41AC2Ev(
  // CHECK:      [[THIS:%.*]] = load [[A:%.*]]** {{%.*}}
  //   Construct single.
  // CHECK-NEXT: [[SINGLE:%.*]] = getelementptr inbounds [[A]]* [[THIS]], i32 0, i32 0
  // CHECK-NEXT: store i8* null, i8** [[SINGLE]], align 8
  //   Construct array.
  // CHECK-NEXT: [[ARRAY:%.*]] = getelementptr inbounds [[A]]* [[THIS]], i32 0, i32 1
  // CHECK-NEXT: [[T0:%.*]] = bitcast [2 x [3 x i8*]]* [[ARRAY]] to i8*
  // CHECK-NEXT: call void @llvm.memset.p0i8.i64(i8* [[T0]], i8 0, i64 48, i32 8, i1 false)
  //   throw 0;
  // CHECK:      invoke void @__cxa_throw(
  //   Landing pad from throw site:
  // CHECK:      landingpad
  //     - First, destroy all of array.
  // CHECK:      [[ARRAYBEGIN:%.*]] = getelementptr inbounds [2 x [3 x i8*]]* [[ARRAY]], i32 0, i32 0, i32 0
  // CHECK-NEXT: [[ARRAYEND:%.*]] = getelementptr inbounds i8** [[ARRAYBEGIN]], i64 6
  // CHECK-NEXT: br label
  // CHECK:      [[AFTER:%.*]] = phi i8** [ [[ARRAYEND]], {{%.*}} ], [ [[ELT:%.*]], {{%.*}} ]
  // CHECK-NEXT: [[ELT]] = getelementptr inbounds i8** [[AFTER]], i64 -1
  // CHECK-NEXT: call void @objc_storeStrong(i8** [[ELT]], i8* null) [[NUW]]
  // CHECK-NEXT: [[DONE:%.*]] = icmp eq i8** [[ELT]], [[ARRAYBEGIN]]
  // CHECK-NEXT: br i1 [[DONE]],
  //     - Next, destroy single.
  // CHECK:      call void @objc_storeStrong(i8** [[SINGLE]], i8* null) [[NUW]]
  // CHECK:      br label
  // CHECK:      resume
}

// CHECK: attributes [[NUW]] = { nounwind }
