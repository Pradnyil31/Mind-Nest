const fs = require("fs");
const path = require("path");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds
} = require("@firebase/rules-unit-testing");
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  collection,
  query,
  where,
  getDocs
} = require("firebase/firestore");

describe("Firestore security rules - critical collections", () => {
  let testEnv;

  const rules = fs.readFileSync(
    path.resolve(__dirname, "..", "..", "firestore.rules"),
    "utf8"
  );

  const CRITICAL_COLLECTIONS = [
    "daily_checkins",
    "journal_entries",
    "meditation_sessions",
    "focus_sessions",
    "routine_completions"
  ];

  const aliceDb = () => testEnv.authenticatedContext("alice").firestore();
  const bobDb = () => testEnv.authenticatedContext("bob").firestore();
  const anonDb = () => testEnv.unauthenticatedContext().firestore();

  async function seedOwnedDoc(collectionName, docId, userId = "alice") {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), collectionName, docId), {
        userId,
        note: "seed-data",
        updatedAt: Date.now()
      });
    });
  }

  beforeAll(async () => {
    const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST;
    const firestoreConfig = emulatorHost
      ? (() => {
          const [host, portRaw] = emulatorHost.split(":");
          return {
            host,
            port: Number(portRaw),
            rules
          };
        })()
      : { rules };

    testEnv = await initializeTestEnvironment({
      projectId: "mindnest-rules-tests",
      firestore: firestoreConfig
    });
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  afterAll(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  test("owner can create and read own user profile", async () => {
    await assertSucceeds(
      setDoc(doc(aliceDb(), "users", "alice"), {
        uid: "alice",
        displayName: "Alice",
        createdAt: new Date()
      })
    );

    await assertSucceeds(getDoc(doc(aliceDb(), "users", "alice")));
    await assertFails(getDoc(doc(bobDb(), "users", "alice")));
  });


  test("user profile create is denied when uid does not match auth uid", async () => {
    await assertFails(
      setDoc(doc(aliceDb(), "users", "alice"), {
        uid: "bob",
        displayName: "Alice",
        createdAt: new Date()
      })
    );
  });


  test("user profile create is denied when createdAt is missing", async () => {
    await assertFails(
      setDoc(doc(aliceDb(), "users", "alice"), {
        uid: "alice",
        displayName: "Alice"
      })
    );
  });
  test("owner can update own user profile without changing immutable fields", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "users", "alice"), {
        uid: "alice",
        displayName: "Alice",
        createdAt: new Date("2025-01-01T00:00:00.000Z")
      });
    });

    await assertSucceeds(
      updateDoc(doc(aliceDb(), "users", "alice"), {
        displayName: "Alice Updated"
      })
    );
  });

  test("owner cannot mutate immutable uid field on user profile", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "users", "alice"), {
        uid: "alice",
        displayName: "Alice",
        createdAt: new Date("2025-01-01T00:00:00.000Z")
      });
    });

    await assertFails(
      updateDoc(doc(aliceDb(), "users", "alice"), {
        uid: "bob"
      })
    );
  });

  test("owner cannot mutate immutable createdAt on user profile", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "users", "alice"), {
        uid: "alice",
        displayName: "Alice",
        createdAt: new Date("2025-01-01T00:00:00.000Z")
      });
    });

    await assertFails(
      updateDoc(doc(aliceDb(), "users", "alice"), {
        createdAt: new Date("2026-01-01T00:00:00.000Z")
      })
    );
  });
  test.each(CRITICAL_COLLECTIONS)(
    "%s: owner can create when userId matches auth.uid",
    async (collectionName) => {
      await assertSucceeds(
        setDoc(doc(aliceDb(), collectionName, "owned-create"), {
          userId: "alice",
          value: "ok"
        })
      );
    }
  );

  test.each(CRITICAL_COLLECTIONS)(
    "%s: create is denied when userId does not match auth.uid",
    async (collectionName) => {
      await assertFails(
        setDoc(doc(aliceDb(), collectionName, "wrong-owner-create"), {
          userId: "bob",
          value: "blocked"
        })
      );
    }
  );

  test.each(CRITICAL_COLLECTIONS)(
    "%s: create is denied when userId is missing",
    async (collectionName) => {
      await assertFails(
        setDoc(doc(aliceDb(), collectionName, "missing-userid"), {
          value: "blocked"
        })
      );
    }
  );

  test.each(CRITICAL_COLLECTIONS)(
    "%s: owner can update mutable fields while keeping userId unchanged",
    async (collectionName) => {
      await seedOwnedDoc(collectionName, "owned-update", "alice");

      await assertSucceeds(
        updateDoc(doc(aliceDb(), collectionName, "owned-update"), {
          note: "updated"
        })
      );
    }
  );

  test.each(CRITICAL_COLLECTIONS)(
    "%s: owner can read and delete own document",
    async (collectionName) => {
      await seedOwnedDoc(collectionName, "owner-read-delete", "alice");

      await assertSucceeds(getDoc(doc(aliceDb(), collectionName, "owner-read-delete")));
      await assertSucceeds(deleteDoc(doc(aliceDb(), collectionName, "owner-read-delete")));
    }
  );

  test.each(CRITICAL_COLLECTIONS)(
    "%s: owner can query own documents by userId",
    async (collectionName) => {
      await seedOwnedDoc(collectionName, "owner-query-1", "alice");
      await seedOwnedDoc(collectionName, "owner-query-2", "alice");

      const q = query(
        collection(aliceDb(), collectionName),
        where("userId", "==", "alice")
      );

      await assertSucceeds(getDocs(q));
    }
  );

  test.each(CRITICAL_COLLECTIONS)(
    "%s: non-owner cannot update owner's document",
    async (collectionName) => {
      await seedOwnedDoc(collectionName, "owner-update-denied", "alice");

      await assertFails(
        updateDoc(doc(bobDb(), collectionName, "owner-update-denied"), {
          note: "hijack-attempt"
        })
      );
    }
  );

  test.each(CRITICAL_COLLECTIONS)(
    "%s: owner cannot mutate immutable userId",
    async (collectionName) => {
      await seedOwnedDoc(collectionName, "immutable-userid", "alice");

      await assertFails(
        updateDoc(doc(aliceDb(), collectionName, "immutable-userid"), {
          userId: "bob"
        })
      );
    }
  );

  test.each(CRITICAL_COLLECTIONS)(
    "%s: owner cannot replace existing document with changed userId via set",
    async (collectionName) => {
      await seedOwnedDoc(collectionName, "immutable-userid-set", "alice");

      await assertFails(
        setDoc(doc(aliceDb(), collectionName, "immutable-userid-set"), {
          userId: "bob",
          note: "replace-attempt"
        })
      );
    }
  );

  test.each(CRITICAL_COLLECTIONS)(
    "%s: owner cannot replace existing document via set without userId",
    async (collectionName) => {
      await seedOwnedDoc(collectionName, "immutable-userid-set-missing", "alice");

      await assertFails(
        setDoc(doc(aliceDb(), collectionName, "immutable-userid-set-missing"), {
          note: "replace-without-userid"
        })
      );
    }
  );

  test.each(CRITICAL_COLLECTIONS)(
    "%s: non-owner cannot read or delete owner's document",
    async (collectionName) => {
      await seedOwnedDoc(collectionName, "owner-doc", "alice");

      await assertFails(getDoc(doc(bobDb(), collectionName, "owner-doc")));
      await assertFails(deleteDoc(doc(bobDb(), collectionName, "owner-doc")));
    }
  );

  test.each(CRITICAL_COLLECTIONS)(
    "%s: non-owner cannot query owner documents",
    async (collectionName) => {
      await seedOwnedDoc(collectionName, "owner-query-denied-1", "alice");
      await seedOwnedDoc(collectionName, "owner-query-denied-2", "alice");

      const q = query(
        collection(bobDb(), collectionName),
        where("userId", "==", "alice")
      );

      await assertFails(getDocs(q));
    }
  );

  test.each(CRITICAL_COLLECTIONS)(
    "%s: unauthenticated client cannot read or delete existing document",
    async (collectionName) => {
      await seedOwnedDoc(collectionName, "anon-read-delete-denied", "alice");

      await assertFails(getDoc(doc(anonDb(), collectionName, "anon-read-delete-denied")));
      await assertFails(deleteDoc(doc(anonDb(), collectionName, "anon-read-delete-denied")));
    }
  );

  test.each(CRITICAL_COLLECTIONS)(
    "%s: unauthenticated client cannot query documents",
    async (collectionName) => {
      await seedOwnedDoc(collectionName, "anon-query-denied", "alice");

      const q = query(
        collection(anonDb(), collectionName),
        where("userId", "==", "alice")
      );

      await assertFails(getDocs(q));
    }
  );

  test.each(CRITICAL_COLLECTIONS)(
    "%s: unauthenticated client cannot create documents",
    async (collectionName) => {
      await assertFails(
        setDoc(doc(anonDb(), collectionName, "anon-create"), {
          userId: "anonymous",
          value: "blocked"
        })
      );
    }
  );
});


