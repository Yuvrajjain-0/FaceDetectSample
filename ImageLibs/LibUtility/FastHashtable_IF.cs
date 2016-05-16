using System;
using System.Collections;

namespace Dpu.Utility
{
    using HKEY = System.Int32;
    using HVALUE = System.Double;
    
    /// <summary>
    /// Summary description for FastHash int to object.
    /// </summary>
    [Serializable]
    public class FastHashtableIF  
    {

        #region Fields
        uint       m_capacity;
        uint       m_mask;
        uint       m_elements;
        int        m_bucket;
        uint       m_collision;
        HKEY[]     m_vkey;
        HVALUE[]   m_vvalue;
        int        m_size;
        double     m_loadFactor;
        #endregion

        const HKEY   Undefined_Key   = HKEY.MinValue;
        const HVALUE Undefined_Value = HVALUE.MinValue;

        #region Construtors 
        public FastHashtableIF (int size, double loadFactor)
        {
            int initial = (int) Math.Ceiling(size / loadFactor);
            m_capacity = (uint) (Math.Pow(2, (uint) Math.Ceiling( Math.Log(initial, 2.0))));
            m_mask = m_capacity - 1;
            m_size = (int) Math.Floor(m_capacity * loadFactor);
            m_loadFactor = loadFactor;
            m_elements  = 0;
            m_bucket    = 0;
            m_collision = 0;

            m_vkey   = new HKEY[m_capacity];
            m_vvalue = new HVALUE[m_capacity];
            Initialize();
        }

//#if INTERNAL_DPU
        public FastHashtableIF()
        {
        }
//#endif // INTERNAL_DPU

        #endregion Construtors 

        #region Methods
        /// <summary>
        /// Initialize the hashtable to empty
        /// </summary>
        public void Initialize()
        {
            m_elements = 0;
            for(uint n = 0; n < m_capacity; ++n) 
            { 
                m_vkey[n] = Undefined_Key;
            }
        }

//#if INTERNAL_DPU
        public void Clear()
        {
            Initialize();
        }
//#endif // INTERNAL_DPU

        /// <summary>
        /// Copy the entries from one hashtable to another. 
        /// </summary>
        public void Copy(FastHashtableIF toTable)
        {
            this.Reset();
            while(this.MoveNext()) 
            {
                toTable.Insert(this.CurrentKey, this.CurrentValue);
            }
        }

        /// <summary>
        /// Double the internal size of the hashtable.  Done when load is too high.
        /// </summary>
        private void DoubleSize()
        {
            FastHashtableIF tmp = new FastHashtableIF(m_size * 2, m_loadFactor);
            this.Copy(tmp);
            
            // Copy the internal structures from the other table.
            m_size       = tmp.m_size;
            m_loadFactor = tmp.m_loadFactor;
            m_vvalue     = tmp.m_vvalue;
            m_vkey       = tmp.m_vkey;
            m_capacity   = tmp.m_capacity;
            m_elements   = tmp.m_elements;
            m_bucket     = 0;
            m_collision  = 0;
        }

//#if INTERNAL_DPU
        /// <summary>
        /// Clone the entries from one hashtable to another.  Assumes the hashtables are internally identical
        /// </summary>
        public FastHashtableIF Clone()
        {
            FastHashtableIF res = new FastHashtableIF(m_size, m_loadFactor);

            for(uint n = 0; n < m_capacity; ++n) 
            { 
                res.m_vkey[n] = m_vkey[n];
                res.m_vvalue[n] = m_vvalue[n];
            }

            return res;
        }


        /// <summary>
        /// Increment the entries of the current hashtable with the entries of the argument.
        /// </summary>
        public void Increment(FastHashtableIF table)
        {
            table.Reset();
            while(table.MoveNext()) 
            {
                this.Increment(table.CurrentKey , table.CurrentValue, 0.0);
            }            
        }

        /// <summary>
        /// Scale all defined entries by this quantity.
        /// </summary>
        public void Scale(HVALUE newScale)
        {
            this.Reset();
            while(this.MoveNext()) 
            {
                CurrentValue *= newScale;                
            }
        }
//#endif // INTERNAL_DPU

        /// <summary>
        /// Find the bucket that contains this key,  or a new one if key is absent.
        /// </summary>
        private uint Find_Bucket(HKEY key) 
        {
            uint bucket = 0;
            // uint bucket = First_Bucket(key);
            // int ttt = (3 * key); 
            // bucket = (uint) ((ttt < 0) ? ((-ttt) % m_capacity) : (ttt % m_capacity));
            uint ukey = (uint) key;
            bucket = (uint) ( ( 7919u * ukey) & m_mask);
            // bucket = (uint) ( ( ukey) & m_mask);
            // bucket = (uint) ( ( key) % m_capacity);
            // uint bucket = First_Bucket(key);
            // bucket = (uint) ((3 * key) % m_capacity);
            
            HKEY key_fetch = m_vkey[bucket];
            uint newBucket = bucket;
            while((key_fetch != Undefined_Key) && (key_fetch != key))
            {
                newBucket = (newBucket + 1) % m_capacity;
                if (newBucket == bucket)
                    throw new Exception("Out of space");
                ++m_collision;
                key_fetch = m_vkey[newBucket];
            }
            return newBucket;
        }

        /// <summary>
        /// Add the key bucket pair.  
        /// </summary>
        private void Add(uint bucket, HKEY key, HVALUE val)
        {
            ++m_elements;
            m_vkey[bucket] = key;
            m_vvalue[bucket] = val;
            if (m_elements > this.m_capacity) 
            {
                this.DoubleSize();
            }
        }
        
        /// <summary>
        /// Insert the key/value pair
        /// </summary>
        public void Insert(HKEY key, HVALUE val) 
        {
            uint bucket = Find_Bucket(key);

            if (m_vkey[bucket] == Undefined_Key) 
            {
                Add(bucket, key, val);
            }
            m_vvalue[bucket] = val;
        }


//#if INTERNAL_DPU
        /// <summary>
        /// Increment the key's value by delta
        /// </summary>
        /// <param name="defaultValue">If the key is missing, then use this as the default value.</param>
        public void Increment(HKEY key, HVALUE delta, HVALUE defaultValue) 
        {
            uint bucket = Find_Bucket(key);

            if (m_vkey[bucket] == Undefined_Key) 
            {
                Add(bucket, key, defaultValue + delta);
            }
            else  
            {
                m_vvalue[bucket] += delta;
            }
        }
//#endif // INTERNAL_DPU

        /// <summary>
        /// Is the key in the hashtable
        /// </summary>
        public bool Contains(HKEY key)
        {
            uint bucket = Find_Bucket(key);
            return key == m_vkey[bucket];
        }

        /// <summary>
        /// Fetch the value associated with the key.
        /// </summary>
        public HVALUE Fetch(HKEY key) 
        {
            uint bucket = Find_Bucket(key);
            if (key == m_vkey[bucket]) 
                return m_vvalue[bucket];
            else 
                return Undefined_Value;
        }

        /// <summary>
        /// Perform associative lookup.  
        /// </summary>
        public HVALUE this [HKEY key] 
        {
            get { return Fetch(key); }
            set { Insert(key, value); }
        }

//#if INTERNAL_DPU
        public static void Test() 
        {
            Console.WriteLine("*********************************************");
            Console.WriteLine("Testing FastHashtableIF");
            int ntest = 1000000;
            int nloop = 5;

            int[] keyList = new int[ntest];

            for(int n = 0; n < ntest; ++n) 
            {
                keyList[n] = SharedRandom.Generator.Next(ntest);
            }
            
            System.DateTime ttt = System.DateTime.Now;

            FastHashtableIF table = new FastHashtableIF(ntest, 0.5f);

            Console.WriteLine("Construction time {0}", ttt - System.DateTime.Now);
            ttt = System.DateTime.Now;

            for (int loop = 0; loop < nloop; ++loop) 
            {
                for(int n = 0; n < ntest; ++n) 
                {
                    //                    HKEY key = (n + 1) * (loop + 1);
                    // HKEY key = n;
                    HKEY key = keyList[n];
                    HVALUE val = 2.0 * n;
                    table[key] = val;
                }
            }

            Console.WriteLine("Insertion time {0}", ttt - System.DateTime.Now);
            Console.WriteLine("    collisions {0}", table.m_collision);

            ttt = System.DateTime.Now;

            HVALUE sum = 0;
            for (int loop = 0; loop < nloop; ++loop) 
            {
                for(int n = 0; n < ntest; ++n) 
                {
                    //                    HKEY key = (n + 1) * (loop + 1);
                    // HKEY key = n;
                    HKEY key = keyList[n];
                    sum += table[key];
                }       
            }

            Console.WriteLine("Lookup time {0} and {1}", ttt - System.DateTime.Now, sum);
            ttt = System.DateTime.Now;

            table.Reset();
            
            for (int loop = 0; loop < nloop; ++loop) 
            {
                table.Reset();
                while(table.MoveNext()) 
                {
                    sum += table.CurrentValue;
                }
            }

            Console.WriteLine("Enumerate time {0} and {1}", ttt - System.DateTime.Now, sum);
            ttt = System.DateTime.Now;

            Console.WriteLine("*********************************************");

            Console.WriteLine("Testing Hashtable");
            
            ttt = System.DateTime.Now;

            Hashtable ht = new Hashtable(ntest, 0.5f);

            Console.WriteLine("Construction time {0}", ttt - System.DateTime.Now);
            ttt = System.DateTime.Now;

            for (int loop = 0; loop < nloop; ++loop) 
            {
                for(int n = 0; n < ntest; ++n) 
                {
                    //                    HKEY key = (n + 1) * (loop + 1);
                    // HKEY key = n;
                    HKEY key = keyList[n];
                    HVALUE val = 2.0 * n;
                    ht[key] = val;
                }
            }

            Console.WriteLine("Insertion time {0}", ttt - System.DateTime.Now);
            ttt = System.DateTime.Now;

            sum = 0;
            for (int loop = 0; loop < nloop; ++loop) 
            {
                for(int n = 0; n < ntest; ++n) 
                {
                    //                    HKEY key = (n + 1) * (loop + 1);
                    // HKEY key = n;
                    HKEY key = keyList[n];
                    sum += (double) ht[key];
                }
            }

            Console.WriteLine("Lookup time {0} and {1}", ttt - System.DateTime.Now, sum);
            ttt = System.DateTime.Now;

            for (int loop = 0; loop < nloop; ++loop) 
            {
                foreach(DictionaryEntry de in ht) 
                {
                    sum += (HVALUE) de.Value;
                }
            }

            Console.WriteLine("Enumerate time {0} and {1}", ttt - System.DateTime.Now, sum);
            ttt = System.DateTime.Now;

            Console.WriteLine("*********************************************");

        }
//#endif // INTERNAL_DPU
        #endregion
        
        #region Enumerator Style Methods
    
        public void Reset()
        {
            m_bucket = -1;
        }

        public bool MoveNext()
        {
            if (m_bucket >= m_capacity)
                return false;
            ++m_bucket;
            while(m_bucket != m_capacity && m_vkey[m_bucket] == Undefined_Key ) 
            {
                ++m_bucket;
            }
            return m_bucket != m_capacity;                
        }

        public HKEY CurrentKey
        {
            get { return m_vkey[m_bucket]; }
        }

        public HVALUE CurrentValue
        {
            get { return m_vvalue[m_bucket]; }
            set { m_vvalue[m_bucket] = value; }
        }

        #endregion

    }



}