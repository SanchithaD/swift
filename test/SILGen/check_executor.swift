// RUN: %target-swift-frontend -emit-silgen %s -module-name test -swift-version 5  -disable-availability-checking -enable-actor-data-race-checks | %FileCheck --enable-var-scope %s --check-prefix=CHECK-RAW
// RUN: %target-swift-frontend -emit-silgen %s -module-name test -swift-version 5  -disable-availability-checking -enable-actor-data-race-checks > %t.sil
// RUN: %target-sil-opt -enable-sil-verify-all %t.sil -lower-hop-to-actor  | %FileCheck --enable-var-scope %s --check-prefix=CHECK-CANONICAL
// REQUIRES: concurrency

import Swift
import _Concurrency

// CHECK-RAW-LABEL: sil [ossa] @$s4test11onMainActoryyF
// CHECK-RAW: extract_executor [[MAIN_ACTOR:%.*]] : $MainActor

// CHECK-CANONICAL-LABEL: sil [ossa] @$s4test11onMainActoryyF
// CHECK-CANONICAL: function_ref @$ss22_checkExpectedExecutor14_filenameStart01_D6Length01_D7IsASCII5_line9_executoryBp_BwBi1_BwBetF
@MainActor public func onMainActor() { }

func takeClosure(_ fn: @escaping () -> Int) { }

@_predatesConcurrency func takeUnsafeMainActorClosure(_ fn: @MainActor @escaping () -> Int) { }

public actor MyActor {
  var counter = 0

  // CHECK-RAW-LABEL: sil private [ossa] @$s4test7MyActorC10getUpdaterSiycyFSiycfU_
  // CHECK-RAW: extract_executor [[ACTOR:%.*]] : $MyActor

  // CHECK-CANONICAL-LABEL: sil private [ossa] @$s4test7MyActorC10getUpdaterSiycyFSiycfU_
  // CHECK-CANONICAL: function_ref @$ss22_checkExpectedExecutor14_filenameStart01_D6Length01_D7IsASCII5_line9_executoryBp_BwBi1_BwBetF
  public func getUpdater() -> (() -> Int) {
    return {
      self.counter = self.counter + 1
      return self.counter
    }
  }

  // CHECK-RAW-LABEL: sil private [ossa] @$s4test7MyActorC0A10UnsafeMainyyFSiyScMYccfU_
  // CHECK-RAW: _checkExpectedExecutor
  // CHECK-RAW: onMainActor
  // CHECK-RAW: return
  public func testUnsafeMain() {
    takeUnsafeMainActorClosure {
      onMainActor()
      return 5
    }
  }
}
