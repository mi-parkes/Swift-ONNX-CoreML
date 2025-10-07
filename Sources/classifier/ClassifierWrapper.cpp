#include "ClassifierWrapper.hpp"
#include <onnxruntime/onnxruntime_cxx_api.h>
#include <algorithm>
#include <memory>
#include <array>

std::vector<float> normalize_coords(const std::vector<float> &coord) {
    const float min_lat = 47.4979f;
    const float max_lat = 52.5251f;
    const float min_lon = -0.1270f;
    const float max_lon = 19.0514f;
    const float epsilon = 1e-8f;

    float normalized_lat = (coord[0] - min_lat) / (max_lat - min_lat + epsilon);
    float normalized_lon = (coord[1] - min_lon) / (max_lon - min_lon + epsilon);

    return {normalized_lat, normalized_lon};
}

// -------------------- PImpl --------------------
struct Classifier::Impl {
    Ort::Env env{ORT_LOGGING_LEVEL_WARNING, "GeoClassifier"};
    std::shared_ptr<Ort::Session> session;
    Ort::AllocatorWithDefaultOptions allocator;

    std::string input_name;
    std::string output_name;
};

// -------------------- ctor/dtor --------------------
Classifier::Classifier() : pImpl(std::make_shared<Impl>()) {}
Classifier::~Classifier() { deinit(); }

// -------------------- init --------------------
int Classifier::minit(const char* modelPath,bool verbose) {
    this->verbose=verbose;
    try {
        Ort::SessionOptions session_options;
        session_options.SetIntraOpNumThreads(1);

        pImpl->session = std::make_unique<Ort::Session>(
            pImpl->env, modelPath, session_options);

        Ort::AllocatedStringPtr input_name_ptr =
            pImpl->session->GetInputNameAllocated(0, pImpl->allocator);
        Ort::AllocatedStringPtr output_name_ptr =
            pImpl->session->GetOutputNameAllocated(0, pImpl->allocator);

        pImpl->input_name = input_name_ptr.get();
        pImpl->output_name = output_name_ptr.get();

        error.clear();
        return 1;
    } catch (const Ort::Exception &e) {
        error = e.what();
        return 0;
    } catch (const std::exception &e) {
        error = e.what();
        return 0;
    }
}

// -------------------- infer --------------------
//int Classifier::infer(const std::vector<float> &coord) {
int Classifier::infer(const float v1,const float v2) {
    if (!pImpl->session) {
        error = "Error: ONNX Runtime not initialized";
        return -1;
    }

    const std::vector<float> coord{v1,v2};
    try {
        std::vector<float> input_tensor_values = normalize_coords(coord);
        std::array<int64_t, 2> input_shape{1, 2};

        Ort::MemoryInfo memory_info =
            Ort::MemoryInfo::CreateCpu(OrtDeviceAllocator, OrtMemTypeCPU);

        Ort::Value input_tensor = Ort::Value::CreateTensor<float>(
            memory_info,
            input_tensor_values.data(),
            input_tensor_values.size(),
            input_shape.data(),
            input_shape.size());

        // ✅ Fix: use arrays, not &c_str()
        const char* input_names[]  = { pImpl->input_name.c_str() };
        const char* output_names[] = { pImpl->output_name.c_str() };

        auto output_tensors =
            pImpl->session->Run(Ort::RunOptions{nullptr},
                                input_names,
                                &input_tensor,
                                1,
                                output_names,
                                1);

        float *output_arr = output_tensors.front().GetTensorMutableData<float>();
        size_t num_classes = output_tensors.front()
                                 .GetTensorTypeAndShapeInfo()
                                 .GetElementCount();

        int pred_class = static_cast<int>(std::distance(
            output_arr, std::max_element(output_arr, output_arr + num_classes)));

        return pred_class;
    } catch (const Ort::Exception &e) {
        error = e.what();
        return -1;
    } catch (const std::exception &e) {
        error = e.what();
        return -1;
    }
}


// -------------------- deinit --------------------
void Classifier::deinit() {
    if (pImpl->session) {
        pImpl->session.reset();
    }
}

// -------------------- misc --------------------
//std::string Classifier::sayHello() const {
//    return "Hello from Classifier library";
//}

std::string Classifier::getLastError() const {
    return error;
}
