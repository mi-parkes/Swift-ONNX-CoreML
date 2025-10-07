#pragma once
#include <string>
#include <memory>
#include <vector>

class Classifier {
public:
    Classifier();
    ~Classifier();

    int minit(const char* modelPath, bool verbose);
    
    // Returns -1 on error, otherwise the predicted class index
    //int infer(const std::vector<float> &coord);
    int infer(const float v1,const float v2);
    
    void deinit();

//    std::string sayHello() const;
    std::string getLastError() const;

private:
    bool verbose;
    std::string error;
    struct Impl;
    std::shared_ptr<Impl> pImpl;
};
//SWIFT_NONCOPYABLE;
