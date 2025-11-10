#!/usr/bin/env python3
"""Check specific user who uploaded files"""
import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate('/opt/flutter/firebase-admin-sdk.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

# Check the user who has files in storage
user_id = 'kjVDFiEisjaN1052U9ddY0J8kbp2'
user_doc = db.collection('users').document(user_id).get()

if user_doc.exists:
    data = user_doc.to_dict()
    print(f"User: {data.get('name')}")
    print(f"Profile Image: {data.get('profile_image')}")
    print(f"National ID Photo: {data.get('national_id_photo')}")
    print(f"Profile Complete: {data.get('is_profile_complete')}")
else:
    print("User not found")
